//
//  SearchViewController.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import RxSwift
import RxCocoa

final class SearchViewController: UIViewController {
    private let searchView = SearchView()
    private let viewModel: SearchViewModel
    private let disposeBag = DisposeBag()
    
    private var recentSearches: [(String, String, String)] = [] // (심볼, 거래소, 날짜)

    // ViewModel 의존성 주입
    init(viewModel: SearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = searchView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        setupTableView()
    }

    private func setupBindings() {
        searchView.searchBar.searchTextField.rx.text
            .orEmpty
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .bind(onNext: { [weak self] query in
                self?.viewModel.search(query: query)
            })
            .disposed(by: disposeBag)

        searchView.searchBar.searchTextField.rx.controlEvent(.editingDidEndOnExit)
            .withLatestFrom(searchView.searchBar.searchTextField.rx.text.orEmpty)
            .subscribe(onNext: { [weak self] query in
                self?.viewModel.saveSearchHistory(query: query)
            })
            .disposed(by: disposeBag)

        viewModel.filteredSearches
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] searches in
                self?.recentSearches = searches
                self?.searchView.tableView.reloadData()
            })
            .disposed(by: disposeBag)

        searchView.clearButton.addTarget(self, action: #selector(clearSearchHistory), for: .touchUpInside)
    }

    private func setupTableView() {
        searchView.tableView.delegate = self
        searchView.tableView.dataSource = self
        searchView.tableView.register(CustomSearchCell.self, forCellReuseIdentifier: CustomSearchCell.identifier)
    }

    @objc private func clearSearchHistory() {
        viewModel.clearSearchHistory()
    }
}

// MARK: - UITableView Delegate & DataSource
extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentSearches.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CustomSearchCell.identifier, for: indexPath) as? CustomSearchCell else {
            return UITableViewCell()
        }

        let search = recentSearches[indexPath.row]
        let symbol = search.0.uppercased() // 심볼 (BTC, ETH 등)
        let exchange = search.1
        let date = search.2

        // 1. 캐시에서 이미지 확인
        var image = CoinImageCache.shared.getImage(for: symbol)

        // 2. 캐시에 없으면 기본 이미지 적용
        if image == nil {
            image = ImageRepository.getImage(for: symbol)
        }

        // 3. 설정
        cell.configure(with: "\(symbol) \(exchange)", date: date, image: image)

        return cell
    }
}

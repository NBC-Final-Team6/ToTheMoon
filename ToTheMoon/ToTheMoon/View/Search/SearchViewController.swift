//
//  SearchViewController.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class SearchViewController: UIViewController {
    private let searchView = SearchView()
    private let viewModel: SearchViewModel
    private let disposeBag = DisposeBag()
    
    private enum SearchMode {
        case recent
        case result
    }
    
    private var searchMode: SearchMode = .recent
    private var searchResults: [(MarketPrice, Bool)] = [] // 검색 결과 저장
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
        
        searchView.searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = false
            navigationItem.title = "관심목록 추가"
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "chevron.left"),
                style: .plain,
                target: self,
                action: #selector(dismissSearch)
            )
        navigationItem.leftBarButtonItem?.tintColor = .text
        searchView.tableView.reloadData()
    }
    
    @objc private func dismissSearch() {
        navigationController?.popViewController(animated: true) 
    }
    
    private func setupBindings() {
        // 검색어 입력 이벤트 처리
        searchView.searchBar.searchTextField.rx.text
            .orEmpty
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .bind(onNext: { [weak self] query in
                self?.viewModel.search(query: query)
            })
            .disposed(by: disposeBag)
        
        // 검색 완료 시 검색어 저장
        searchView.searchBar.searchTextField.rx.controlEvent(.editingDidEndOnExit)
            .withLatestFrom(searchView.searchBar.searchTextField.rx.text.orEmpty)
            .subscribe(onNext: { [weak self] query in
                self?.viewModel.saveSearchHistory(query: query)
            })
            .disposed(by: disposeBag)
        
        // 검색 결과와 저장 상태 결합 바인딩
        viewModel.combinedSearchResults
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] combinedResults in
                guard let self = self else { return }
                
                print(combinedResults)
                self.searchResults = combinedResults
                self.searchMode = combinedResults.isEmpty ? .recent : .result
                self.searchView.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        // 최근 검색 기록 바인딩
        viewModel.recentSearches
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] searches in
                guard let self = self else { return }
                
                // 최근 검색 기록 업데이트
                self.recentSearches = searches
                if self.searchMode == .recent {
                    self.searchView.tableView.reloadData()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setupTableView() {
        searchView.tableView.delegate = self
        searchView.tableView.dataSource = self
        searchView.tableView.register(CustomSearchCell.self, forCellReuseIdentifier: CustomSearchCell.identifier)
        searchView.tableView.register(FavoritesViewCell.self, forCellReuseIdentifier: FavoritesViewCell.identifier)
    }
    
    @objc private func clearSearchHistory() {
        viewModel.clearSearchHistory()
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchMode == .recent ? recentSearches.count : searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searchMode == .recent {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CustomSearchCell.identifier, for: indexPath) as? CustomSearchCell else {
                return UITableViewCell()
            }
            let search = recentSearches[indexPath.row]
            let symbol = search.0.uppercased()
            let exchange = search.1
            let date = search.2
            let image = CoinImageCache.shared.getImage(for: symbol) ?? ImageRepository.getImage(for: symbol)
            
            cell.configure(with: "\(symbol) \(exchange)", date: date, image: image)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: FavoritesViewCell.identifier, for: indexPath) as? FavoritesViewCell else {
                return UITableViewCell()
            }
            let (marketPrice, isSaved): (MarketPrice, Bool) = searchResults[indexPath.row]
            cell.configure(with: marketPrice, isSaved: isSaved)
            
            cell.addButtonAction = { [weak self] coin in
                guard let self = self else { return }
                
                self.viewModel.toggleFavorite(coin)
                
                if let index = self.searchResults.firstIndex(where: { $0.0.symbol == coin.symbol && $0.0.exchange == coin.exchange }) {
                    self.searchResults[index].1.toggle()
                }
                
                self.searchView.tableView.reloadData()
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard searchMode == .recent, !recentSearches.isEmpty else { return nil }
        
        let headerView = UIView()
        headerView.backgroundColor = .background
        
        let titleLabel = UILabel()
        titleLabel.text = "최근 검색"
        titleLabel.textColor = .text
        titleLabel.font = .boldSystemFont(ofSize: 16)
        
        let clearButton = UIButton()
        clearButton.setTitle("검색 기록 지우기", for: .normal)
        clearButton.setTitleColor(.text, for: .normal)
        clearButton.titleLabel?.font = .medium.regular()
        clearButton.rx.tap
            .bind { [weak self] in
                self?.clearSearchHistory()
            }
            .disposed(by: disposeBag)
        
        [ titleLabel, clearButton ].forEach{ headerView.addSubview($0)}
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        clearButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return searchMode == .recent && !recentSearches.isEmpty ? 40 : 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return searchMode == .recent ? 70 : 60
    }
    
    // MARK: - 최근 검색 기록을 클릭하면 해당 검색어로 검색 수행
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard searchMode == .recent else { return }
        let selectedSearch = recentSearches[indexPath.row]
        let searchQuery = selectedSearch.0
        searchView.searchBar.text = searchQuery
        viewModel.search(query: searchQuery)
        searchView.searchBar.resignFirstResponder()
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}


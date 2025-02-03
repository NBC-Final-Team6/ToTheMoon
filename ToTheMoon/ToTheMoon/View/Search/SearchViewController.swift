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
    private var searchResults: [MarketPrice] = [] // 검색 결과 저장
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
        navigationItem.leftBarButtonItem?.tintColor = .personel
        searchView.tableView.reloadData()
    }
    
    @objc private func dismissSearch() {
        navigationController?.popViewController(animated: true) // 이전 화면으로 돌아가기
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
        
        // 검색 결과 바인딩
        viewModel.filteredSearchResults
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] results in
                self?.searchResults = results
                self?.searchMode = results.isEmpty ? .recent : .result
                self?.searchView.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        // 최근 검색 기록 바인딩
        viewModel.recentSearches
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] searches in
                self?.recentSearches = searches
                if self?.searchMode == .recent {
                    self?.searchView.tableView.reloadData()
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
            // 최근 검색 기록은 CustomSearchCell을 사용
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CustomSearchCell.identifier, for: indexPath) as? CustomSearchCell else {
                return UITableViewCell()
            }
            
            let search = recentSearches[indexPath.row]
            let symbol = search.0.uppercased() // 심볼 (BTC, ETH 등)
            let exchange = search.1
            let date = search.2
            var image = CoinImageCache.shared.getImage(for: symbol)
            if image == nil {
                image = ImageRepository.getImage(for: symbol)
            }
            cell.configure(with: "\(symbol) \(exchange)", date: date, image: image)
    
            return cell
        } else {
            // 검색 결과는 FavoritesViewCell을 사용
            guard let cell = tableView.dequeueReusableCell(withIdentifier: FavoritesViewCell.identifier, for: indexPath) as? FavoritesViewCell else {
                return UITableViewCell()
            }
            
            let marketPrice = searchResults[indexPath.row]
            
            cell.disposeBag = DisposeBag()
            
            // 저장된 코인 여부 확인 후 UI 업데이트 (symbol + exchange 기반)
            viewModel.isCoinSaved(marketPrice.symbol, exchange: marketPrice.exchange)
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { isSaved in
                    cell.configure(with: marketPrice, isSaved: isSaved)
                })
                .disposed(by: cell.disposeBag)

            // 버튼 클릭 시 Core Data 저장 처리
            cell.addButtonAction = { [weak self] selectedCoin in
                guard let self = self else { return }
                self.viewModel.toggleFavorite(selectedCoin)
                if let updatedCell = self.searchView.tableView.cellForRow(at: indexPath) as? FavoritesViewCell {
                    updatedCell.toggleButtonState()
                }
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
        return searchMode == .recent ? UITableView.automaticDimension : 60
    }
    
    // MARK: - 최근 검색 기록을 클릭하면 해당 검색어로 검색 수행
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard searchMode == .recent else { return }
        let selectedSearch = recentSearches[indexPath.row]
        let searchQuery = selectedSearch.0 // 심볼 (BTC, ETH 등)
        searchView.searchBar.text = searchQuery
        viewModel.search(query: searchQuery)
        searchView.searchBar.resignFirstResponder()
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder() // 키보드 내리기
    }
}


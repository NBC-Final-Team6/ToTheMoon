//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/27/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class FavoriteListViewController: UIViewController {
    
    // MARK: - UI Components
    private let contentView = FovoritesListTableView()
    private let noFavoritesView = NoFavoritesView()
    private let loadingView = LoadingView()
    
    // MARK: - Properties
    private let viewModel: FavoritesListViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(viewModel: FavoritesListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    override func loadView() {
        view = UIView()
        view.backgroundColor = .background
        
        [contentView, noFavoritesView, loadingView].forEach {
            view.addSubview($0)
            $0.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        view.layoutIfNeeded()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        contentView.tableView.delegate = self
        noFavoritesView.addButton.addTarget(self, action: #selector(navigateToSearch), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.input.fetchTrigger.accept(())
    }
    
    // MARK: - Bind ViewModel
    private func setupBindings() {
        let output = viewModel.output
        // ⭐ 즐겨찾기 코인 리스트 바인딩
        output.favoriteCoins
            .drive(contentView.tableView.rx.items(
                cellIdentifier: CoinPriceTableViewCell.identifier,
                cellType: CoinPriceTableViewCell.self)
            ) { _, coin, cell in
                print(coin)
                self.contentView.tableView.reloadData()
                cell.configure(with: coin)
            }
            .disposed(by: disposeBag)
        
        // ⭐ 로딩 상태 바인딩
        output.isLoading
            .drive(onNext: { [weak self] isLoading in
                guard let self = self else { return }
                self.loadingView.isHidden = !isLoading
                self.contentView.isHidden = isLoading
                self.noFavoritesView.isHidden = isLoading
            })
            .disposed(by: disposeBag)
        
        // ⭐ 즐겨찾기 코인 유무에 따른 뷰 표시
        output.favoriteCoins
            .map { !$0.isEmpty } // true: 코인 있음, false: 없음
            .drive(onNext: { [weak self] hasFavorites in
                guard let self = self else { return }
                print("📌 hasFavorites:", hasFavorites)
                self.contentView.isHidden = !hasFavorites
                self.noFavoritesView.isHidden = hasFavorites
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - 검색 화면 이동
    @objc private func navigateToSearch() {
        let getMarketPricesUseCase = GetMarketPricesUseCase(
            services: [
                BithumbService(),
                CoinOneService(),
                KorbitService(),
                UpbitService()
            ],
            symbolService: SymbolService()
        )
        let manageFavoritesUseCase = ManageFavoritesUseCase()
        let searchViewModel = SearchViewModel(
            getMarketPricesUseCase: getMarketPricesUseCase,
            manageFavoritesUseCase: manageFavoritesUseCase
        )
        let searchVC = SearchViewController(viewModel: searchViewModel)
        navigationController?.pushViewController(searchVC, animated: true)
    }
}

// MARK: - UITableViewDelegate
extension FavoriteListViewController: UITableViewDelegate {
    
    // 셀 높이 설정
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    // ⭐ 스와이프 삭제 기능 적용 (ViewModel Input 사용)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completionHandler in
            guard let self = self else {
                completionHandler(false)
                return
            }
            
            self.viewModel.output.favoriteCoins
                .drive(onNext: { [weak self] coins in
                    guard let self = self, indexPath.row < coins.count else {
                        completionHandler(false)
                        return
                    }
                    
                    let coin = coins[indexPath.row]
                    self.viewModel.input.removeFavorite.accept(coin) // ✅ ViewModel의 Input을 통해 삭제 요청
                    completionHandler(true)
                })
                .disposed(by: self.disposeBag)
        }
        deleteAction.backgroundColor = UIColor.red
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}


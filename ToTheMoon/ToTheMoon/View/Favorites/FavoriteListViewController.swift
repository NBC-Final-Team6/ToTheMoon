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
    private let contentView = FovoritesListTableView()
    private let noFavoritesView = NoFavoritesView()
    private let loadingView = LoadingView()
    private let viewModel: FavoritesListViewModel
    private let disposeBag = DisposeBag()
    
    init(viewModel: FavoritesListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = UIView() // 기본 View 설정
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
        viewModel.fetchFavoriteCoins()
    }
    
    private func setupBindings() {
        Observable.combineLatest(viewModel.favoriteCoins, viewModel.isLoading)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (coins, isLoading) in
                guard let self = self else { return }
                
                if isLoading {
                    self.loadingView.startLoading()
                    self.contentView.isHidden = true
                    self.noFavoritesView.isHidden = true
                } else {
                    self.loadingView.stopLoading()
                    let hasFavorites = !coins.isEmpty
                    self.contentView.isHidden = !hasFavorites
                    self.noFavoritesView.isHidden = hasFavorites
                    self.contentView.tableView.reloadData()
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.favoriteCoins
            .observe(on: MainScheduler.instance)
            .bind(to: contentView.tableView.rx.items(cellIdentifier: CoinPriceTableViewCell.identifier, cellType: CoinPriceTableViewCell.self)) { _, coin, cell in
                cell.configure(with: coin)
            }
            .disposed(by: disposeBag)
        
        contentView.floatingButton.rx.tap
            .bind { [weak self] in
                self?.navigateToSearch()
            }
            .disposed(by: disposeBag)
    }
    
    @objc private func navigateToSearch() {
        let getMarketPricesUseCase = GetMarketPricesUseCase()
        let manageFavoritesUseCase = ManageFavoritesUseCase()
        let searchViewModel = SearchViewModel(
            getMarketPricesUseCase: getMarketPricesUseCase,
            manageFavoritesUseCase: manageFavoritesUseCase
        )
        let searchVC = SearchViewController(viewModel: searchViewModel)
        navigationController?.pushViewController(searchVC, animated: true)
    }
}

extension FavoriteListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completionHandler in
            guard let self = self else {
                completionHandler(false)
                return
            }
            self.viewModel.favoriteCoins
                .take(1)
                .subscribe(onNext: { coins in
                    guard indexPath.row < coins.count else {
                        completionHandler(false) 
                        return
                    }
                    let coin = coins[indexPath.row]
                    self.viewModel.removeFavoriteCoin(coin)
                    completionHandler(true)
                }, onError: { error in
                    print("❌ 삭제할 코인을 가져오는 중 오류 발생: \(error.localizedDescription)")
                    completionHandler(false)
                })
                .disposed(by: self.disposeBag)
        }
        deleteAction.backgroundColor = UIColor.red
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}


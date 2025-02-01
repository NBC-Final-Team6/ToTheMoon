//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/27/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class FavoriteListViewController: UIViewController {
    private let contentView = CustomTableView()
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
        view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        contentView.tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        viewModel.fetchFavoriteCoins()
    }
    
    private func setupBindings() {
        viewModel.favoriteCoins
            .observe(on: MainScheduler.instance)
            .bind(to: contentView.tableView.rx.items(cellIdentifier: CoinPriceTableViewCell.identifier, cellType: CoinPriceTableViewCell.self)) { _, coin, cell in
                cell.configure(with: coin)
            }
            .disposed(by: disposeBag)
        
        contentView.tableView.rx.modelSelected(MarketPrice.self)
            .subscribe(onNext: { print("Selected coin: \($0.symbol)") })
            .disposed(by: disposeBag)
        
        viewModel.favoriteCoins
            .map { $0.isEmpty } // 데이터가 없으면 true
            .distinctUntilChanged()
            .bind(to: contentView.tableView.rx.isHidden)
            .disposed(by: disposeBag)
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
                        completionHandler(false) // 인덱스 초과 방지
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

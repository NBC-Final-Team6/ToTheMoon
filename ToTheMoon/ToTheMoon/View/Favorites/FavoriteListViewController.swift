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

    private func setupBindings() {
        // ✅ ViewModel의 favoriteCoins를 테이블 뷰에 바인딩
        viewModel.favoriteCoins
            .observe(on: MainScheduler.instance) // UI 업데이트는 메인 스레드에서 실행
            .bind(to: contentView.tableView.rx.items(cellIdentifier: CoinPriceTableViewCell.identifier, cellType: CoinPriceTableViewCell.self)) { _, coin, cell in
                print("✅ 바인딩된 코인: \(coin.symbol)")
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
}

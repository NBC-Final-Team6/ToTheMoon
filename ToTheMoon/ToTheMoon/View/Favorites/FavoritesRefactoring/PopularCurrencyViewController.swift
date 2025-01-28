//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/28/25.
//

import UIKit
import RxSwift
import RxCocoa

final class PopularCurrencyViewController: UIViewController {
    private let contentView = CustomTableView()
    private let viewModel = FavoritesViewModel()
    private let disposeBag = DisposeBag()

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        viewModel.fetchPopularCoins()
        contentView.tableView.delegate = self
    }

    private func bindViewModel() {
        viewModel.popularCoins
            .bind(to: contentView.tableView.rx.items(cellIdentifier: CoinPriceTableViewCell2.cellIdentifier, cellType: CoinPriceTableViewCell2.self)) { _, coin, cell in
                cell.configure(with: coin)
            }
            .disposed(by: disposeBag)
        
        contentView.tableView.rx.modelSelected(MarketPrice.self)
            .subscribe(onNext: { print("Selected coin: \($0.symbol)") })
            .disposed(by: disposeBag)
    }
}

extension PopularCurrencyViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

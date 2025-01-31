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
    private let viewModel = FavoritesListViewModel()
    private let disposeBag = DisposeBag()

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        viewModel.fetchfavoritesCoins() // 데이터 가져오기
        contentView.tableView.delegate = self
    }

    private func setupBindings() {
        // ViewModel의 favoritesCoins를 테이블 뷰 데이터 소스에 바인딩
        viewModel.favoritesCoins
            .bind(to: contentView.tableView.rx.items(cellIdentifier: CoinPriceTableViewCell.identifier, cellType: CoinPriceTableViewCell.self)) { _, marketPrice, cell in
                cell.configure(with: marketPrice)
            }
            .disposed(by: disposeBag)

        // 데이터의 유무에 따라 뷰를 업데이트
        viewModel.favoritesCoins
            .map { !$0.isEmpty } // 데이터가 비어있지 않으면 true
            .distinctUntilChanged() // 중복된 값은 무시
            .observe(on: MainScheduler.instance) // UI 업데이트는 메인 스레드에서 수행
            .subscribe(onNext: { [weak self] hasData in
                self?.updateUI(hasData: hasData)
            })
            .disposed(by: disposeBag)
    }

    private func updateUI(hasData: Bool) {
        contentView.tableView.isHidden = !hasData
    }
}

extension FavoriteListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

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
        viewModel.fetchFavoriteCoins() // ✅ CoreData에서 저장된 코인 불러오기
    }

    private func setupBindings() {
        // ✅ ViewModel의 favoriteCoins를 테이블 뷰에 바인딩
        viewModel.favoriteCoins
            .bind(to: contentView.tableView.rx.items(
                cellIdentifier: CoinPriceTableViewCell.identifier,
                cellType: CoinPriceTableViewCell.self
            )) { _, marketPrice, cell in
                cell.configure(with: marketPrice)
            }
            .disposed(by: disposeBag)

        // ✅ 데이터의 유무에 따라 UI 업데이트
        viewModel.favoriteCoins
            .map { !$0.isEmpty } // 데이터가 있으면 true
            .distinctUntilChanged() // 중복된 값은 무시
            .bind(to: contentView.tableView.rx.isHidden) // ✅ 테이블 뷰 가시성 업데이트
            .disposed(by: disposeBag)
    }
}

extension FavoriteListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

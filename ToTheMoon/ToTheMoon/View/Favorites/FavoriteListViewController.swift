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
        
        // 즐겨찾기 코인 리스트 바인딩
        output.favoriteCoins
            .drive(contentView.tableView.rx.items(
                cellIdentifier: CoinPriceTableViewCell.identifier,
                cellType: CoinPriceTableViewCell.self)
            ) { _, coin, cell in
                cell.configure(with: coin)
            }
            .disposed(by: disposeBag)
        
        // 로딩 상태 바인딩
        output.isLoading
            .drive(loadingView.rx.isHidden)
            .disposed(by: disposeBag)
        
        // 관심목록 UI 상태 업데이트
        output.favoriteCoins
            .map { !$0.isEmpty }
            .drive(onNext: { [weak self] hasFavorites in
                guard let self = self else { return }
                self.contentView.isHidden = !hasFavorites
                self.noFavoritesView.isHidden = hasFavorites
                self.loadingView.isHidden = true
            })
            .disposed(by: disposeBag)
        
        contentView.tableView.rx.modelDeleted(MarketPrice.self)
            .bind(to: viewModel.input.removeFavorite)
            .disposed(by: disposeBag)
    }
    
    // MARK: - 검색 화면 이동
    @objc private func navigateToSearch() {
        let searchVC = SearchViewController(viewModel: SearchViewModel(
            getMarketPricesUseCase: GetMarketPricesUseCase(
                services: [BithumbService(), CoinOneService(), KorbitService(), UpbitService()],
                symbolService: SymbolService()
            ),
            manageFavoritesUseCase: ManageFavoritesUseCase()
        ))
        navigationController?.pushViewController(searchVC, animated: true)
    }
}

// MARK: - UITableViewDelegate
extension FavoriteListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}


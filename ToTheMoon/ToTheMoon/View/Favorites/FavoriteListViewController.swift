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
    
    // MARK: - UI Components (초기에는 nil)
    private var contentView: FovoritesListTableView?
    private var noFavoritesView: NoFavoritesView?
    private var loadingView: LoadingView?
    
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
    }
    
    // MARK: - Bind ViewModel
    private func setupBindings() {
        let output = viewModel.output

        // `viewWillAppear`을 감지하여 fetchFavoriteCoins() 호출
        self.rx.viewWillAppear
            .subscribe(onNext: { [weak self] in
                self?.viewModel.fetchFavoriteCoins()
            })
            .disposed(by: disposeBag)
        
        // UI 상태 업데이트 (로딩, 데이터 유무 반영)
        Driver
            .combineLatest(output.isLoading, output.favoriteCoins)
            .drive(onNext: { [weak self] isLoading, favoriteCoins in
                self?.updateUI(isLoading: isLoading, hasFavorites: !favoriteCoins.isEmpty, coins: favoriteCoins)
            })
            .disposed(by: disposeBag)
        
        // Rx 방식으로 검색 버튼 이벤트 바인딩
        noFavoritesView?.addButton.rx.tap
            .bind(to: viewModel.input.searchTrigger)
            .disposed(by: disposeBag)
    }
    
    // MARK: - UI 업데이트 (상황에 맞는 뷰 추가 및 제거)
    private func updateUI(isLoading: Bool, hasFavorites: Bool, coins: [MarketPrice]) {
        removeAllSubviews()

        if isLoading {
            showLoadingView()
        } else if hasFavorites {
            showContentView(with: coins)
        } else {
            showNoFavoritesView()
        }
    }
    
    // MARK: - 로딩 화면 표시
    private func showLoadingView() {
        let loadingView = LoadingView()
        self.loadingView = loadingView
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - 데이터가 있을 때 contentView 표시
    private func showContentView(with coins: [MarketPrice]) {
        let contentView = FovoritesListTableView()
        self.contentView = contentView
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 테이블 뷰 Rx 바인딩 (삭제 포함)
        bindTableView(to: contentView, coins: coins)
        
        // Rx 방식으로 delegate 설정
        contentView.tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)
    }
    
    private func showNoFavoritesView() {
        let noFavoritesView = NoFavoritesView()
        self.noFavoritesView = noFavoritesView
        view.addSubview(noFavoritesView)
        noFavoritesView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Rx 방식으로 검색 버튼 이벤트 바인딩
        noFavoritesView.addButton.rx.tap
            .bind(to: viewModel.input.searchTrigger)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Rx 바인딩: 테이블 뷰 데이터 + 스와이프 삭제
    private func bindTableView(to contentView: FovoritesListTableView, coins: [MarketPrice]) {
        let tableView = contentView.tableView
        
        // 테이블 뷰 데이터 바인딩
        Observable.just(coins)
            .observe(on: MainScheduler.instance)
            .bind(to: tableView.rx.items(
                cellIdentifier: CoinPriceTableViewCell.identifier,
                cellType: CoinPriceTableViewCell.self)
            ) { _, coin, cell in
                cell.configure(with: coin)
            }
            .disposed(by: disposeBag)
        
        // 스와이프 삭제 이벤트 추가
        tableView.rx.modelDeleted(MarketPrice.self)
            .bind(to: viewModel.input.removeFavorite)
            .disposed(by: disposeBag)
    }
    
    // MARK: - 기존 UI 제거 (새로운 UI 추가 전)
    private func removeAllSubviews() {
        contentView?.removeFromSuperview()
        noFavoritesView?.removeFromSuperview()
        loadingView?.removeFromSuperview()
        
        contentView = nil
        noFavoritesView = nil
        loadingView = nil
    }
    
    // MARK: - 검색 화면 이동
    private func navigateToSearch() {
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
    
    // 스와이프 삭제 활성화
    private func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}

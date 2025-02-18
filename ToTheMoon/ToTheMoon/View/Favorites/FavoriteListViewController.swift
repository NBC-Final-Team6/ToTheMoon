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
    private lazy var contentView = FovoritesListTableView()
    private lazy var noFavoritesView = NoFavoritesView()
    private lazy var loadingView = LoadingView()
    
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
        setupViews()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchFavoriteCoinsChartData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.fetchFavoriteCoinsUseCase.cancelSubscriptions()
    }
    
    // MARK: - UI 초기화
    private func setupViews() {
        
        [ contentView, noFavoritesView, loadingView ].forEach { view.addSubview($0) }
        
        contentView.snp.makeConstraints { $0.edges.equalToSuperview() }
        noFavoritesView.snp.makeConstraints { $0.edges.equalToSuperview() }
        loadingView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        contentView.isHidden = true
        noFavoritesView.isHidden = true
        loadingView.isHidden = true
    }
    
    // MARK: - Bind ViewModel
    private func setupBindings() {
        let output = viewModel.output
        
        // 화면이 나타날 때마다 데이터 가져오기
        self.rx.viewWillAppear
            .map { _ in }
            .bind(to: viewModel.input.viewWillAppearTrigger)
            .disposed(by: disposeBag)
        
        // UI 상태 업데이트
        Driver.combineLatest(output.isLoading, output.favoriteCoins)
            .drive(onNext: { [weak self] isLoading, favoriteCoins in
                self?.updateUI(isLoading: isLoading, hasFavorites: !favoriteCoins.isEmpty, coins: favoriteCoins)
            })
            .disposed(by: disposeBag)
        
        // 검색 화면 이동 트리거
        output.navigateToSearch
            .emit(onNext: { [weak self] in
                self?.navigateToSearch()
            })
            .disposed(by: disposeBag)
        
        // 테이블 뷰 데이터 바인딩
        Driver.combineLatest(output.favoriteCoins, output.favoriteCoinsChartData)
            .map { coins, candles in
                return coins.map { coin in
                    let relatedCandles = candles.filter { $0.symbol == coin.symbol }
                    return (coin, relatedCandles)
                }
            }
            .drive(contentView.tableView.rx.items(
                cellIdentifier: CoinPriceTableViewCell.identifier,
                cellType: CoinPriceTableViewCell.self)
            ) { index, item, cell in
                let (coin, relatedCandles) = item
                cell.configure(with: coin, candles: relatedCandles)
            }
            .disposed(by: disposeBag)
        
        // 테이블 뷰 델리게이트 self 설정
        contentView.tableView.rx.setDelegate(self)
                    .disposed(by: disposeBag)
        // 스와이프 삭제 이벤트 추가
        contentView.tableView.rx.modelDeleted(MarketPrice.self)
            .bind(to: viewModel.input.removeFavorite)
            .disposed(by: disposeBag)
    }
    
    // MARK: - UI 업데이트 (뷰 삭제 없이 상태만 변경)
    private func updateUI(isLoading: Bool, hasFavorites: Bool, coins: [MarketPrice]) {
        loadingView.isHidden = !isLoading
        contentView.isHidden = !(hasFavorites && !isLoading)
        noFavoritesView.isHidden = hasFavorites || isLoading
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



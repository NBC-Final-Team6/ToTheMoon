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
import RxDataSources

final class FavoriteListViewController: UIViewController {
    
    // MARK: - UI Components
    private lazy var topFavoritesView = TopFavoritesView()
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
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.fetchFavoriteCoinsUseCase.cancelSubscriptions()
    }
    
    // MARK: - UI 초기화
    private func setupViews() {
        view.backgroundColor = .background
        
        [ topFavoritesView, contentView, noFavoritesView, loadingView ].forEach { view.addSubview($0) }
        
        topFavoritesView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(100)
        }
        
        contentView.snp.makeConstraints { make in
            make.top.equalTo(topFavoritesView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        noFavoritesView.snp.makeConstraints { $0.edges.equalTo(contentView) }
        loadingView.snp.makeConstraints { $0.edges.equalTo(contentView) }
        
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
        topFavoritesView.searchButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigateToSearch()
            })
            .disposed(by: disposeBag)
        
        noFavoritesView.addButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigateToSearch()
            })
            .disposed(by: disposeBag)
        
        // 관심 목록 개수 업데이트
        output.favoriteCoins
            .map { $0.count }
            .distinctUntilChanged()
            .drive(onNext: { [weak self] count in
                self?.topFavoritesView.countLabel.text = "(\(count))"
                self?.topFavoritesView.deleteButton.isHidden = (count == 0)
            })
            .disposed(by: disposeBag)
        
        contentView.tableView.rx.modelSelected((MarketPrice, [Candle]).self)
            .subscribe(onNext: { [weak self] selectedItem in
                guard let self = self else { return }
                let (marketPrice, _) = selectedItem
                self.navigateToChartView(for: marketPrice)
            })
            .disposed(by: disposeBag)
        
        Driver.combineLatest(output.favoriteCoins, output.favoriteCoinsChartData)
                   .map { (coins: [MarketPrice], candles: [Candle]) -> [(MarketPrice, [Candle])] in
                       return coins.compactMap { coin in
                           let relatedCandles = candles.filter {
                               $0.symbol == coin.symbol || $0.symbol == "KRW-\(coin.symbol)"
                           }
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
        
        // 테이블 뷰 델리게이트 설정
        contentView.tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        // 스와이프 삭제 이벤트 추가
//        contentView.tableView.rx.modelDeleted((MarketPrice, [Candle]).self)
//            .map { $0.0 }
//            .bind(to: viewModel.input.removeFavorite)
//            .disposed(by: disposeBag)
        
        // 전체 삭제 버튼 클릭 시 모두 삭제
        topFavoritesView.deleteButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showDeleteConfirmationAlert()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - UI 업데이트 (뷰 삭제 없이 상태만 변경)
    private func updateUI(isLoading: Bool, hasFavorites: Bool, coins: [MarketPrice]) {
        if isLoading {
            // 데이터를 불러오는 중이면 로딩 화면을 보이게 하고 나머지는 숨김
            loadingView.isHidden = false
            contentView.isHidden = true
            noFavoritesView.isHidden = true
        } else {
            // 데이터 로딩이 끝났을 때 UI 업데이트
            loadingView.isHidden = true
            contentView.isHidden = !hasFavorites
            noFavoritesView.isHidden = hasFavorites
        }
    }
    
    // MARK: Alert 창
    private func showDeleteConfirmationAlert() {
        let alert = UIAlertController(title: "경고", message: "정말로 삭제하시겠습니까?", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.fetchFavoriteCoinsUseCase.cancelSubscriptions()
            self.viewModel.input.removeAllFavorites.accept(())
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.viewModel.fetchFavoriteCoins()
            }
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - 검색 화면 이동
    private func navigateToSearch() {
        let searchVC = SearchViewController(viewModel: SearchViewModel(
            getMarketPricesUseCase: GetMarketPricesUseCase(

                services: [ BithumbService(), CoinOneService(), KorbitService(), UpbitService()],

                symbolService: SymbolService()
            ),
            manageFavoritesUseCase: ManageFavoritesUseCase()
        ))
        navigationController?.pushViewController(searchVC, animated: true)
    }
    
    // MARK: - 차트 화면 이동
    private func navigateToChartView(for marketPrice: MarketPrice) {
        let exchange = Exchange(rawValue: marketPrice.exchange) ?? nil
        let chartViewModel = ChartViewModel(exchange: exchange, selectedCoins: [marketPrice])
        let coinPriceViewModel = CoinPriceViewModel()
        let chartVC = ChartViewController(viewModel: chartViewModel)
        navigationController?.pushViewController(chartVC, animated: true)
    }
}

// MARK: - UITableViewDelegate
extension FavoriteListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}



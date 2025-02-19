//
//  FavoritesViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//
import RxSwift
import RxCocoa
final class FavoritesListViewModel {
    
    // MARK: - Dependencies
    private let manageFavoritesUseCase: ManageFavoritesUseCaseProtocol
    let fetchFavoriteCoinsUseCase: FetchFavoriteCoinsUseCase
    let fetchFavoriteCoinsChartUseCase: FetchFavoriteCoinsChartUseCase
    private let disposeBag = DisposeBag()
    
    // MARK: - Input
    struct Input {
        let removeFavorite = PublishRelay<MarketPrice>()
        let removeAllFavorites = PublishRelay<Void>()
        let searchTrigger = PublishRelay<Void>()
        let viewWillAppearTrigger = PublishRelay<Void>()
        let viewWillDisappearTrigger = PublishRelay<Void>()
    }
    
    // MARK: - Output
    struct Output {
        let favoriteCoins: Driver<[MarketPrice]>
        let favoriteCoinsCount: Driver<Int>
        let favoriteCoinsChartData: Driver<[Candle]>
        let isLoading: Driver<Bool>
        let navigateToSearch: Signal<Void>
    }
    
    // MARK: - Properties
    let input = Input()
    let output: Output
    
    private let favoriteCoinsRelay = BehaviorRelay<[MarketPrice]>(value: [])
    private let favoriteCoinsCountRelay = BehaviorRelay<Int>(value: 0)
    private let favoriteCoinsChartRelay = BehaviorRelay<[Candle]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Init
    init(
        manageFavoritesUseCase: ManageFavoritesUseCaseProtocol,
        fetchFavoriteCoinsUseCase: FetchFavoriteCoinsUseCase,
        fetchFavoriteCoinsChartUseCase: FetchFavoriteCoinsChartUseCase
    ) {
        self.manageFavoritesUseCase = manageFavoritesUseCase
        self.fetchFavoriteCoinsUseCase = fetchFavoriteCoinsUseCase
        self.fetchFavoriteCoinsChartUseCase = fetchFavoriteCoinsChartUseCase
        
        self.output = Output(
            favoriteCoins: favoriteCoinsRelay.asDriver(onErrorJustReturn: []),
            favoriteCoinsCount: favoriteCoinsCountRelay.asDriver(onErrorJustReturn: 0),
            favoriteCoinsChartData: favoriteCoinsChartRelay.asDriver(onErrorJustReturn: []),
            isLoading: isLoadingRelay.asDriver(onErrorJustReturn: false),
            navigateToSearch: input.searchTrigger.asSignal()
        )
        
        bindInputs()
        bindFavoriteCoinsCount()
    }
    
    // MARK: - Bind Input to Output
    private func bindInputs() {
        input.viewWillAppearTrigger
            .subscribe(onNext: { [weak self] in
                self?.fetchFavoriteCoins()
            })
            .disposed(by: disposeBag)
        
        input.viewWillDisappearTrigger
            .subscribe(onNext: { [weak self] in
                self?.fetchFavoriteCoinsUseCase.cancelSubscriptions()
            })
            .disposed(by: disposeBag)
        
        input.removeFavorite
            .flatMapLatest { [weak self] coin -> Observable<Void> in
                guard let self = self else { return .empty() }
                return self.manageFavoritesUseCase.removeCoin(coin)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.fetchFavoriteCoins()
            })
            .disposed(by: disposeBag)
        
        input.removeAllFavorites
            .withLatestFrom(favoriteCoinsRelay)
            .flatMap { [weak self] coins -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                return Observable.from(coins)
                    .concatMap { coin in
                        self.manageFavoritesUseCase.removeCoin(coin)
                    }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                print("모든 관심 코인 삭제 완료")
                self?.fetchFavoriteCoins() // 삭제 후 UI 업데이트
            })
            .disposed(by: disposeBag)
    }
    
    private func bindFavoriteCoinsCount() {
        favoriteCoinsRelay
            .map { $0.count }
            .distinctUntilChanged()
            .bind(to: favoriteCoinsCountRelay)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Fetch Favorite Coins (웹소켓 사용)
    func fetchFavoriteCoins() {
        isLoadingRelay.accept(true)
        
        fetchFavoriteCoinsUseCase.fetchFavoriteCoinsRealtimeData()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] allMarketPrices in
                self?.isLoadingRelay.accept(false)
                guard let self = self else { return }
                // 모든 거래소의 데이터를 한 번에 업데이트
                self.favoriteCoinsRelay.accept(allMarketPrices)
                //allMarketPrices.forEach { print("   💰 \($0.exchange) - \($0.symbol): \($0.price) KRW") }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Fetch Favorite Coins Chart Data (1분봉 180개 요청)
    func fetchFavoriteCoinsChartData() {
        fetchFavoriteCoinsChartUseCase.fetchFavoriteCoinsChartData(interval: .hour, count: 24)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] candles in
                guard let self = self else { return }
                self.favoriteCoinsChartRelay.accept(candles)
            })
            .disposed(by: disposeBag)
    }
    
    deinit {
        fetchFavoriteCoinsUseCase.cancelSubscriptions() // 뷰모델이 해제될 때 웹소켓 해제
    }
}




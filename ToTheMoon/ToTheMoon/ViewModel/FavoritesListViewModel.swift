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
    private let disposeBag = DisposeBag()
    
    // MARK: - Input
    struct Input {
        let removeFavorite = PublishRelay<MarketPrice>()
        let searchTrigger = PublishRelay<Void>()
        let viewWillAppearTrigger = PublishRelay<Void>()
        let viewWillDisappearTrigger = PublishRelay<Void>()
    }
    
    // MARK: - Output
    struct Output {
        let favoriteCoins: Driver<[MarketPrice]>
        let isLoading: Driver<Bool>
        let navigateToSearch: Signal<Void>
    }
    
    // MARK: - Properties
    let input = Input()
    let output: Output
    
    private let favoriteCoinsRelay = BehaviorRelay<[MarketPrice]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Init
    init(manageFavoritesUseCase: ManageFavoritesUseCaseProtocol, fetchFavoriteCoinsUseCase: FetchFavoriteCoinsUseCase) {
        self.manageFavoritesUseCase = manageFavoritesUseCase
        self.fetchFavoriteCoinsUseCase = fetchFavoriteCoinsUseCase
        
        self.output = Output(
            favoriteCoins: favoriteCoinsRelay.asDriver(onErrorJustReturn: []),
            isLoading: isLoadingRelay.asDriver(onErrorJustReturn: false),
            navigateToSearch: input.searchTrigger.asSignal()
        )
        
        bindInputs()
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
    }
    
    // MARK: - Fetch Favorite Coins (웹소켓 사용)
    func fetchFavoriteCoins() {
        isLoadingRelay.accept(true)
        
        fetchFavoriteCoinsUseCase.fetchFavoriteCoinsRealtimeData()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] allMarketPrices in
                self?.isLoadingRelay.accept(false)
                guard let self = self else { return }
                // ✅ 모든 거래소의 데이터를 한 번에 업데이트
                self.favoriteCoinsRelay.accept(allMarketPrices)
                print("🟢 [DEBUG] 최종 MarketPrice 리스트 (UI 업데이트 직전):")
                allMarketPrices.forEach { print("   💰 \($0.exchange) - \($0.symbol): \($0.price) KRW") }
            })
            .disposed(by: disposeBag)
    }
    
    deinit {
        print("🔴 FavoritesListViewModel deinit - 웹소켓 연결 해제")
        fetchFavoriteCoinsUseCase.cancelSubscriptions() // 뷰모델이 해제될 때 웹소켓 해제
    }
}

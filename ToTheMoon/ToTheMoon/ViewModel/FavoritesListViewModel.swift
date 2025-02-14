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
    private let fetchFavoriteCoinsUseCase: FetchFavoriteCoinsUseCase
    private let disposeBag = DisposeBag()
    
    // MARK: - Input
    struct Input {
        let removeFavorite = PublishRelay<MarketPrice>()
        let searchTrigger = PublishRelay<Void>()
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
    
    // MARK: - Fetch Favorite Coins (WebSocket 사용)
    func fetchFavoriteCoins() {
        isLoadingRelay.accept(true)
        
        fetchFavoriteCoinsUseCase.fetchFavoriteCoinsRealtimeData()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] marketPrices in
                    self?.isLoadingRelay.accept(false)
                    self?.favoriteCoinsRelay.accept(marketPrices)
                },
                onError: { [weak self] _ in
                    self?.isLoadingRelay.accept(false)
                }
            )
            .disposed(by: disposeBag)
    }
}

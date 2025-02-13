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
    private let getMarketPricesUseCase: GetMarketPricesUseCase
    private let disposeBag = DisposeBag()
    
    // MARK: - Input
    struct Input {
        let removeFavorite = PublishRelay<MarketPrice>()
    }
    
    // MARK: - Output
    struct Output {
        let favoriteCoins: Driver<[MarketPrice]>
        let isLoading: Driver<Bool>
    }
    
    // MARK: - Properties
    let input = Input()
    let output: Output
    
    private let favoriteCoinsRelay = BehaviorRelay<[MarketPrice]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Init
    init(manageFavoritesUseCase: ManageFavoritesUseCaseProtocol, getMarketPricesUseCase: GetMarketPricesUseCase) {
        self.manageFavoritesUseCase = manageFavoritesUseCase
        self.getMarketPricesUseCase = getMarketPricesUseCase

        self.output = Output(
            favoriteCoins: favoriteCoinsRelay.asDriver(onErrorJustReturn: []),
            isLoading: isLoadingRelay.asDriver(onErrorJustReturn: false)
        )
        
        bindInputs()
    }
    
    // MARK: - Bind Input to Output
    private func bindInputs() {
        // 즐겨찾기 코인 삭제
        input.removeFavorite
            .flatMapLatest { [weak self] coin -> Observable<Void> in
                guard let self = self else { return .empty() }
                return self.manageFavoritesUseCase.removeCoin(coin)
            }
            .subscribe(onNext: { [weak self] in
                self?.fetchFavoriteCoins()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Fetch Favorite Coins
    func fetchFavoriteCoins() {
        isLoadingRelay.accept(true)

        let savedCoinsObservable = manageFavoritesUseCase.fetchFavoriteCoins()
            .asObservable()

        let allMarketPricesSingle = getMarketPricesUseCase.execute()
        
        Observable.combineLatest(savedCoinsObservable, allMarketPricesSingle.asObservable())
            .map { savedCoins, marketPrices in
                return marketPrices.filter { marketPrice in
                    savedCoins.contains { $0.symbol == marketPrice.symbol && $0.exchangename == marketPrice.exchange }
                }
            }
            .do(onNext: { [weak self] filteredCoins in
                self?.isLoadingRelay.accept(false)
                self?.favoriteCoinsRelay.accept(filteredCoins)
            }, onError: { [weak self] error in
                self?.isLoadingRelay.accept(false)
            })
            .subscribe()
            .disposed(by: disposeBag)
    }
}

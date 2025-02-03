//
//  FavoritesViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import RxSwift
import RxCocoa

final class PopularCurrencyViewModel {
    private let getMarketPricesUseCase: GetMarketPricesUseCase
    private let manageFavoritesUseCase: ManageFavoritesUseCaseProtocol
    private let disposeBag = DisposeBag()
    
    let popularCoins = BehaviorRelay<[MarketPrice]>(value: [])
    let selectedCoins = BehaviorRelay<Set<MarketPrice>>(value: [])
    let isFavoriteButtonVisible = BehaviorRelay<Bool>(value: false)
    
    init(getMarketPricesUseCase: GetMarketPricesUseCase = GetMarketPricesUseCase(),
         manageFavoritesUseCase: ManageFavoritesUseCaseProtocol = ManageFavoritesUseCase()) {
        self.getMarketPricesUseCase = getMarketPricesUseCase
        self.manageFavoritesUseCase = manageFavoritesUseCase
        fetchPopularCoins()
    }
    
    func fetchPopularCoins() {
        Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .flatMapLatest { [weak self] _ in
                self?.getMarketPricesUseCase.execute()
                    .map { marketPrices in
                        marketPrices.sorted(by: { $0.quoteVolume > $1.quoteVolume })
                    }
                    .asObservable()
                    .catchAndReturn([])
                ?? Observable.just([])
            }
            .bind(to: popularCoins)
            .disposed(by: disposeBag)
    }
    
    func toggleSelection(for coin: MarketPrice) {
        var updatedSelection = selectedCoins.value
        if updatedSelection.contains(coin) {
            updatedSelection.remove(coin)
        } else {
            updatedSelection.insert(coin)
        }
        selectedCoins.accept(updatedSelection)
        
        isFavoriteButtonVisible.accept(!updatedSelection.isEmpty)
    }
    
    func addSelectedToFavorites() {
        let coinsToSave = Array(selectedCoins.value)
        guard !coinsToSave.isEmpty else { return }
        
        selectedCoins.accept([])
        isFavoriteButtonVisible.accept(false)
        
        let saveOperations = coinsToSave.map { manageFavoritesUseCase.saveCoin($0) }
        Observable.zip(saveOperations)
            .subscribe(onNext: { _ in
                print("✅ 관심 목록에 추가 완료!")
            }, onError: { error in
                print("❌ 관심 목록 추가 실패: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
}

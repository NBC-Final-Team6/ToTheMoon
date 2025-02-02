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
    }
    
    func fetchPopularCoins() {
        getMarketPricesUseCase.execute()
            .map { marketPrices in
                marketPrices.sorted(by: { $0.quoteVolume > $1.quoteVolume })
            }
            .subscribe(onSuccess: { [weak self] sortedCoins in
                self?.popularCoins.accept(sortedCoins)
            }, onError: { error in
                print("❌ 인기 코인 데이터 가져오기 실패: \(error.localizedDescription)")
            })
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

        let saveOperations = coinsToSave.map { manageFavoritesUseCase.saveCoin($0) }
        Observable.zip(saveOperations)
            .subscribe(onNext: { _ in
                print("✅ 관심 목록에 추가 완료!")
            }, onError: { error in
                print("❌ 관심 목록 추가 실패: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
        
        selectedCoins.accept([])
        isFavoriteButtonVisible.accept(false)
    }
}

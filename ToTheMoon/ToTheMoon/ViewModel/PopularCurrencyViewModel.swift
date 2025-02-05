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
    
    // ✅ Output
    let popularCoins = BehaviorRelay<[(MarketPrice, [Candle])]>(value: [])
    let selectedCoins = BehaviorRelay<Set<MarketPrice>>(value: [])
    let isFavoriteButtonVisible = BehaviorRelay<Bool>(value: false)
    
    let showAlertMessage = PublishSubject<String>()

    init(getMarketPricesUseCase: GetMarketPricesUseCase = GetMarketPricesUseCase(),
         manageFavoritesUseCase: ManageFavoritesUseCaseProtocol = ManageFavoritesUseCase()) {
        self.getMarketPricesUseCase = getMarketPricesUseCase
        self.manageFavoritesUseCase = manageFavoritesUseCase
        fetchPopularCoins()
    }
    
    func fetchPopularCoins() {
        getMarketPricesUseCase.execute()
            .map { marketData in
                marketData.sorted(by: { $0.0.quoteVolume > $1.0.quoteVolume }) // ✅ 거래량 기준 정렬
            }
            .asObservable()
            .catchAndReturn([])
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

        Observable.from(coinsToSave)
            .flatMap { coin in
                self.manageFavoritesUseCase.isCoinSaved(coin.symbol, exchange: coin.exchange)
                    .map { isSaved in (coin, isSaved) }
                    .asObservable()
            }
            .toArray()
            .asObservable()
            .flatMap { results -> Observable<Void> in
                let alreadySavedCoins = results.filter { $0.1 }.map { $0.0 }
                let newCoins = results.filter { !$0.1 }.map { $0.0 }

                if !alreadySavedCoins.isEmpty {
                    let coinNames = alreadySavedCoins.map { $0.symbol }.joined(separator: ", ")
                    let message = "\(coinNames)는(은) 이미 관심 목록에 추가되어 있습니다."
                    self.showAlertMessage.onNext(message)
                }

                guard !newCoins.isEmpty else { return Observable.just(()) }
                let saveOperations = newCoins.map { self.manageFavoritesUseCase.saveCoin($0).asObservable() }
                return Observable.zip(saveOperations) { _ in }
            }
            .subscribe(onNext: {
                print("✅ 관심 목록에 추가 완료!")
            }, onError: { error in
                print("❌ 관심 목록 추가 실패: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
}

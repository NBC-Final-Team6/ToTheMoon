//
//  FavoritesViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import RxSwift
import RxCocoa

final class FavoritesListViewModel {
    private let manageFavoritesUseCase: ManageFavoritesUseCaseProtocol
    private let disposeBag = DisposeBag()
    
    private let upbitService = UpbitService()
    private let bithumbService = BithumbService()
    private let korbitService = KorbitService()
    private let coinOneService = CoinOneService()

    private let favoriteCoinsRelay = BehaviorRelay<[MarketPrice]>(value: [])

    var favoriteCoins: Observable<[MarketPrice]> {
        return favoriteCoinsRelay.asObservable()
    }

    init(manageFavoritesUseCase: ManageFavoritesUseCaseProtocol) {
        self.manageFavoritesUseCase = manageFavoritesUseCase
        fetchFavoriteCoins()
    }

    /// ✅ Core Data에서 저장된 코인 목록을 가져오고, API 요청을 실행하여 최신 데이터를 가져온다.
    func fetchFavoriteCoins() {
        manageFavoritesUseCase.fetchFavoriteCoins()
            .flatMap { [weak self] savedCoins -> Observable<[MarketPrice]> in
                guard let self = self else { return Observable.just([]) }

                let requests = savedCoins.compactMap { coin -> Observable<[MarketPrice]>? in
                    guard let symbol = coin.symbol, let exchange = coin.exchangename else { return nil }
                    return self.fetchMarketPrice(for: symbol, exchange: exchange)
                }
                return Observable.zip(requests)
                    .map { $0.flatMap { $0 } }
            }
            .subscribe(onNext: { [weak self] marketPrices in
                self?.favoriteCoinsRelay.accept(marketPrices)
            }, onError: { error in
                print("❌ 코인 가격 가져오기 실패: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }

    /// ✅ 특정 거래소에 맞는 `fetchMarketPrice(symbol:)` 메서드를 호출하여 데이터를 가져온다.
    private func fetchMarketPrice(for symbol: String, exchange: String) -> Observable<[MarketPrice]> {
        guard let exchangeEnum = Exchange(rawValue: exchange) else { 
            return Observable.just([])
        }
        switch exchangeEnum {
        case .upbit:
            return upbitService.fetchMarketPrice(symbol: symbol)
                .asObservable()

        case .bithumb:
            return bithumbService.fetchMarketPrice(symbol: symbol)
                .asObservable()

        case .korbit:
            return korbitService.fetchMarketPrice(symbol: symbol)
                .asObservable()

        case .coinone:
            return coinOneService.fetchMarketPrice(symbol: symbol)
                .asObservable()
        }
    }
}

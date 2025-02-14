//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/14/25.
//

import Foundation
import RxSwift

final class FetchFavoriteCoinsUseCase {
    private let webSocketServices: [WebSocketServiceProtocol]
    private let manageFavoritesUseCase: ManageFavoritesUseCaseProtocol

    init(manageFavoritesUseCase: ManageFavoritesUseCaseProtocol, webSocketServices: [WebSocketServiceProtocol]) {
        self.manageFavoritesUseCase = manageFavoritesUseCase
        self.webSocketServices = webSocketServices
    }

    func fetchFavoriteCoinsRealtimeData() -> Observable<[MarketPrice]> {
        return manageFavoritesUseCase.fetchFavoriteCoins()
            .flatMap { [weak self] favoriteCoins -> Observable<[MarketPrice]> in
                guard let self = self else { return Observable.just([]) }

                // 거래소별 코인 심볼 분류
                var symbolsByExchange: [Exchange: [String]] = [:]
                for coin in favoriteCoins {
                    guard let exchange = Exchange(rawValue: coin.exchangename?.lowercased() ?? ""),
                          let symbol = coin.symbol else { continue }
                    symbolsByExchange[exchange, default: []].append(symbol)
                }

                // 각 거래소별 웹소켓 서비스에서 데이터 가져오기
                let observables = self.webSocketServices.compactMap { service -> Observable<[MarketPrice]>? in
                    guard let symbols = symbolsByExchange[service.exchange], !symbols.isEmpty else {
                        return Observable.just([])
                    }
                    return service.fetchKrwTicker(for: symbols)
                }

                // 모든 데이터 병합하여 반환
                return Observable.combineLatest(observables)
                    .map { $0.flatMap { $0 } } // 모든 배열을 하나의 배열로 합침
            }
    }
}

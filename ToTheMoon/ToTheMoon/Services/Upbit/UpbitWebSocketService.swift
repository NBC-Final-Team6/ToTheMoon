//
//  UpbitWebSocketService.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//

import Foundation
import RxSwift

final class UpbitWebSocketService: WebSocketServiceProtocol {
    var exchange: Exchange = .upbit
    
    private let upbitService = UpbitService()
    private var cachedSymbols: [String] = []

    private func loadAllKrwSymbols() -> Single<[String]> {
        return upbitService.fetchMarketPrices()
            .map { markets in
                markets.filter { $0.symbol.hasPrefix("KRW-") }
                    .map { $0.symbol.replacingOccurrences(of: "KRW-", with: "") }
            }
            .do(onSuccess: { [weak self] symbols in
                self?.cachedSymbols = symbols
            })
    }

    func fetchAllKrwTickers() -> Observable<[MarketPrice]> {
        let symbolsObservable: Single<[String]> = cachedSymbols.isEmpty ? loadAllKrwSymbols() : .just(cachedSymbols)

        return symbolsObservable.asObservable()
            .flatMap { symbols -> Observable<UpbitWebSocketTickerResponse> in
                guard !symbols.isEmpty else {
                    return Observable.error(NetworkError.invalidData)
                }

                return UpbitWebSocketManager.shared.connect(
                    symbols: symbols,
                    decodingType: UpbitWebSocketTickerResponse.self
                )
            }
            .map { [$0] }
            .map { $0.toMarketPrices(exchange: .upbit) }
    }
    
    // **특정 코인들의 WebSocket 구독**
    func fetchKrwTicker(for symbols: [String]) -> Observable<[MarketPrice]> {
        return UpbitWebSocketManager.shared.connect(
            symbols: symbols,
            decodingType: UpbitWebSocketTickerResponse.self
        )
        .map { [$0] }
        .map { $0.toMarketPrices(exchange: .upbit) }
    }
}

extension Array where Element == UpbitWebSocketTickerResponse {
    func toMarketPrices(exchange: Exchange) -> [MarketPrice] {
        return self.map { ticker in
            MarketPrice(
                symbol: ticker.code,
                price: ticker.tradePrice,
                exchange: exchange.rawValue,
                change: ticker.change,
                changeRate: ticker.changeRate * 100,
                quoteVolume: ticker.accTradeVolume,
                highPrice: ticker.highPrice,
                lowPrice: ticker.lowPrice
            )
        }
    }
}

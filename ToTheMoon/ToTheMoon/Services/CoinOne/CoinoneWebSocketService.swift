//
//  CoinoneWebSocketService.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//

import Foundation
import RxSwift

final class CoinoneWebSocketService {
    let exchange: Exchange = .coinone
    private let coinoneService = CoinOneService()
    private var cachedSymbols: [String] = []

    private func loadAllKrwSymbols() -> Single<[String]> {
        return coinoneService.fetchMarketPrices()
            .map { marketPrices in
                let symbols = marketPrices.map { $0.symbol }
                return symbols.map { $0.lowercased().replacingOccurrences(of: "krw-", with: "") }
            }
            .do(onSuccess: { [weak self] symbols in
                self?.cachedSymbols = symbols
            })
    }

    /// ✅ 20개 WebSocket을 유지하면서 모든 코인을 점진적으로 구독하는 방식으로 변경
    func fetchAllKrwTickers() -> Observable<[MarketPrice]> {
        let symbolsObservable: Single<[String]> = cachedSymbols.isEmpty ? loadAllKrwSymbols() : .just(cachedSymbols)

        return symbolsObservable.asObservable()
            .flatMap { symbols -> Observable<[MarketPrice]> in
                guard !symbols.isEmpty else {
                    return Observable.error(NetworkError.invalidData)
                }

                // ✅ WebSocketManager를 통해 20개 WebSocket 유지하면서 모든 코인을 점진적으로 구독
                return CoinoneWebSocketManager.shared.connect(symbols: symbols)
                    .flatMap { (response: CoinoneWebSocketResponse) -> Observable<[MarketPrice]> in
                        let marketPrices = response.toMarketPrices(exchange: self.exchange)
                        return marketPrices.isEmpty ? Observable.empty() : Observable.just(marketPrices)
                    }
            }
    }
}

extension CoinoneWebSocketResponse {
    func toMarketPrices(exchange: Exchange) -> [MarketPrice] {
        switch self {
        case .data(let tickerDataResponse):
            let tickerData = tickerDataResponse.data
            let formattedSymbol = "\(tickerData.quoteCurrency)-\(tickerData.targetCurrency)"
            let currentPrice = Double(tickerData.last) ?? 0.0
            let highPrice = Double(tickerData.high) ?? 0.0
            let lowPrice = Double(tickerData.low) ?? 0.0
            let quoteVolume = Double(tickerData.quoteVolume) ?? 0.0

            let yesterdayPrice = Double(tickerData.yesterdayLast) ?? 0.0
            let changeRate = yesterdayPrice != 0 ? ((currentPrice - yesterdayPrice) / yesterdayPrice) * 100 : 0
            let change: String = changeRate > 0 ? "RISE" : (changeRate < 0 ? "FALL" : "EVEN")

            return [
                MarketPrice(
                    symbol: formattedSymbol,
                    price: currentPrice,
                    exchange: exchange.rawValue,
                    change: change,
                    changeRate: changeRate,
                    quoteVolume: quoteVolume,
                    highPrice: highPrice,
                    lowPrice: lowPrice
                )
            ]

        default:
            return []
        }
    }
}

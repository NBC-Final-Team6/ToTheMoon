//
//  KorbitWebSocketService.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//

import Foundation
import RxSwift

final class KorbitWebSocketService {
    let exchange: Exchange = .korbit
    private let baseURL = Exchange.korbit.webSocketURL
    private let korbitService = KorbitService()
    private var cachedSymbols: [String] = []

    private func loadAllKrwSymbols() -> Single<[String]> {
        return korbitService.fetchMarketPrices()
            .map { marketPrices in
                let krwMarkets = marketPrices.map { $0.symbol }
                return krwMarkets
            }
            .do(onSuccess: { [weak self] symbols in
                self?.cachedSymbols = symbols
            })
    }

    func fetchAllKrwTickers() -> Observable<[MarketPrice]> {
        let symbolsObservable: Single<[String]> = cachedSymbols.isEmpty ? loadAllKrwSymbols() : .just(cachedSymbols)

        return symbolsObservable.asObservable()
            .flatMap { symbols -> Observable<KorbitWebSocketResponse> in
                guard !symbols.isEmpty else {
                    return Observable.error(NetworkError.invalidData)
                }

                let requestPayload = KorbitWebSocketRequest(
                    method: "subscribe",
                    type: "ticker",
                    symbols: symbols
                )

                return KorbitWebSocketManager.shared.connect(
                    to: URL(string: self.baseURL)!,
                    decodingType: KorbitWebSocketResponse.self,
                    requestPayload: [requestPayload]
                )
            }
            .map { response in response.toMarketPrices(exchange: .korbit) }
    }
}

// MARK: - Response Mapping

extension KorbitWebSocketResponse {
    func toMarketPrices(exchange: Exchange) -> [MarketPrice] {
        let formattedSymbol = self.symbol
        let currentPrice = Double(self.data.close) ?? 0.0
        let highPrice = Double(self.data.high) ?? 0.0
        let lowPrice = Double(self.data.low) ?? 0.0
        let quoteVolume = Double(self.data.volume) ?? 0.0
        let changeRate = Double(self.data.priceChangePercent) ?? 0.0
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
    }
}

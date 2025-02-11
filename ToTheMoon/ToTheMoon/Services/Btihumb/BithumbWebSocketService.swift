//
//  Untitled.swift
//  WebSocketTest
//
//  Created by 황석범 on 2/10/25.
//

import Foundation
import RxSwift

final class BithumbWebSocketService {
    let exchange: Exchange = .bithumb
    private let baseURL = Exchange.bithumb.webSocketURL
    private let bithumbService = BithumbService()
    private var cachedSymbols: [String] = []

    private func loadAllKrwSymbols() -> Single<[String]> {
        return bithumbService.fetchAllMarkets()
            .map { markets in
                let krwMarkets = markets.filter { $0.hasPrefix("KRW-") }
                return krwMarkets.map { $0.replacingOccurrences(of: "KRW-", with: "") }
            }
            .do(onSuccess: { [weak self] symbols in
                self?.cachedSymbols = symbols
            })
    }

    func fetchAllKrwTickers() -> Observable<[MarketPrice]> {
        let symbolsObservable: Single<[String]> = cachedSymbols.isEmpty ? loadAllKrwSymbols() : .just(cachedSymbols)

        return symbolsObservable.asObservable()
            .flatMap { symbols -> Observable<BithumbWebSocketTickerResponse> in
                guard !symbols.isEmpty else {
                    return Observable.error(NetworkError.invalidData)
                }
                
                let requestPayload = BithumbWebSocketTickerRequest(
                    type: "ticker",
                    symbols: symbols.map { "\($0)_KRW" },
                    tickTypes: ["24H"]
                )

                return BithumbWebSocketManager.shared.connect(
                    to: URL(string: self.baseURL)!,
                    decodingType: BithumbWebSocketTickerResponse.self,
                    requestPayload: requestPayload
                )
            }
            .map { response in response.toMarketPrices(exchange: self.exchange) }
    }
}

extension BithumbWebSocketTickerResponse {
    func toMarketPrices(exchange: Exchange) -> [MarketPrice] {
        guard let tickerData = self.content else { return [] }

        let formattedSymbol = tickerData.symbol
        let currentPrice = Double(tickerData.closePrice) ?? 0.0
        let highPrice = Double(tickerData.highPrice) ?? 0.0
        let lowPrice = Double(tickerData.lowPrice) ?? 0.0
        let quoteVolume = Double(tickerData.volume) ?? 0.0
        let changeRate = Double(tickerData.chgRate) ?? 0.0
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


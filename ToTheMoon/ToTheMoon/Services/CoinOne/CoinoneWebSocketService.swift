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

    // 코인 목록을 불러오는 함수 (캐싱 활용)
    private func loadAllKrwSymbols() -> Single<[String]> {
        return coinoneService.fetchMarketPrices()
            .map { marketPrices in
                marketPrices.map { $0.symbol.lowercased().replacingOccurrences(of: "krw-", with: "") }
            }
            .do(onSuccess: { [weak self] symbols in
                self?.cachedSymbols = symbols
            })
    }

    // **모든 코인을 점진적으로 구독 (20개 WebSocket 유지)**
    func fetchAllKrwTickers() -> Observable<[MarketPrice]> {
        let symbolsObservable: Single<[String]> = cachedSymbols.isEmpty ? loadAllKrwSymbols() : .just(cachedSymbols)

        return symbolsObservable.asObservable()
            .flatMap { symbols -> Observable<[MarketPrice]> in
                guard !symbols.isEmpty else {
                    return Observable.error(NetworkError.invalidData)
                }

                return CoinoneWebSocketManager.shared.connect(symbols: symbols)
                    .flatMap { (response: CoinoneWebSocketResponse) -> Observable<[MarketPrice]> in
                        let marketPrices = response.toMarketPrices(exchange: self.exchange)
                        return marketPrices.isEmpty ? Observable.empty() : Observable.just(marketPrices)
                    }
            }
    }
    
    // **개별 코인 WebSocket 구독 요청**
    func fetchKrwTicker(for symbol: String) -> Observable<MarketPrice> {
        return CoinoneWebSocketManager.shared.connectSingle(symbol: symbol)
            .flatMap { (response: CoinoneWebSocketResponse) -> Observable<MarketPrice> in
                let marketPrices = response.toMarketPrices(exchange: self.exchange)
                return marketPrices.isEmpty ? Observable.empty() : Observable.just(marketPrices.first!)
            }
    }

    // **특정 코인의 WebSocket 연결 해제**
    func disconnectKrwTicker(for symbol: String) {
        CoinoneWebSocketManager.shared.disconnectSingle(symbol: symbol)
    }
}

extension CoinoneWebSocketResponse {
    func toMarketPrices(exchange: Exchange) -> [MarketPrice] {
        guard case .data(let tickerDataResponse) = self else { return [] }

        let tickerData = tickerDataResponse.data
        let formattedSymbol = "\(tickerData.quoteCurrency)-\(tickerData.targetCurrency)".uppercased()
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
    }
}

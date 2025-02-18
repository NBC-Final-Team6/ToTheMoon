//
//  CoinoneWebSocketService.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//

import Foundation
import RxSwift

final class CoinoneWebSocketService: WebSocketServiceProtocol {
    var exchange: Exchange = .coinone
    
    private let coinoneService = CoinOneService()
    private var cachedSymbols: [String] = []
    
    private func loadAllKrwSymbols() -> Single<[String]> {
        return coinoneService.fetchMarketPrices()
            .map { marketPrices in
                marketPrices.map { $0.symbol.lowercased().replacingOccurrences(of: "krw-", with: "") }
            }
            .do(onSuccess: { [weak self] symbols in
                self?.cachedSymbols = symbols
            })
    }
    
    func fetchAllKrwTickers() -> Observable<[MarketPrice]> {
        let symbolsObservable: Single<[String]> = cachedSymbols.isEmpty ? loadAllKrwSymbols() : .just(cachedSymbols)
        
        return symbolsObservable.asObservable()
            .flatMap { symbols -> Observable<[MarketPrice]> in
                guard !symbols.isEmpty else {
                    return Observable.error(NetworkError.invalidData)
                }
                
                return CoinoneWebSocketManager.shared.connect(symbols: symbols)
                    .flatMap { (response: CoinoneWebSocketResponse) -> Observable<[MarketPrice]> in
                        let marketPrices = response.toMarketPrices(exchange: .coinone)
                        return marketPrices.isEmpty ? Observable.empty() : Observable.just(marketPrices)
                    }
            }
    }
    
    // **특정 코인들의 WebSocket 구독 요청**
    func fetchKrwTicker(for symbols: [String]) -> Observable<[MarketPrice]> {
        if symbols.isEmpty {
            print("⚠️ [DEBUG] 요청된 심볼이 없음 → WebSocket 연결 해제")
            CoinoneWebSocketManager.shared.disconnectAll()
            return Observable.just([])
        }
        return CoinoneWebSocketManager.shared.connect(symbols: symbols)
            .flatMap { (response: CoinoneWebSocketResponse) -> Observable<[MarketPrice]> in
                let marketPrices = response.toMarketPrices(exchange: .coinone)
                return marketPrices.isEmpty ? Observable.empty() : Observable.just(marketPrices)
            }
    }
    
    func disconnectWebSocket() {
        CoinoneWebSocketManager.shared.disconnectAll()
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

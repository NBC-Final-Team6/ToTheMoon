//
//  KorbitWebSocketService.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//

import Foundation
import RxSwift

final class KorbitWebSocketService: WebSocketServiceProtocol {
    var exchange: Exchange = .korbit
    
    private let korbitService = KorbitService()
    private var cachedSymbols: [String] = []
    
    private func loadAllKrwSymbols() -> Single<[String]> {
        return korbitService.fetchMarketPrices()
            .map { marketPrices in
                marketPrices.map { $0.symbol }
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
                
                return KorbitWebSocketManager.shared.connect(
                    symbols: symbols,
                    decodingType: KorbitWebSocketResponse.self
                )
            }
            .map { response in response.toMarketPrices(exchange: .korbit) }
    }
    
    private func formatSymbol(_ symbol: String) -> String {
        return "\(symbol.lowercased())_krw"
    }
    
    // **특정 코인들의 WebSocket 구독**
    func fetchKrwTicker(for symbols: [String]) -> Observable<[MarketPrice]> {
        if symbols.isEmpty {
            print("⚠️ [DEBUG] 요청된 심볼이 없음 → WebSocket 연결 해제")
            KorbitWebSocketManager.shared.disconnectAll()
            return Observable.just([])
        }
        let formattedSymbols = symbols.map { formatSymbol($0) } // ✅ 심볼 변환 적용
        
        return KorbitWebSocketManager.shared.connect(
            symbols: formattedSymbols, // 변환된 심볼 전달
            decodingType: KorbitWebSocketResponse.self
        )
        .map { $0.toMarketPrices(exchange: .korbit) }
    }
    
    func disconnectWebSocket() {
        KorbitWebSocketManager.shared.disconnectAll()
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

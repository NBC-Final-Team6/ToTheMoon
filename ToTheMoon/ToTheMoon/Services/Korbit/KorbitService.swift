//
//  KorbitService.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

import Foundation
import RxSwift

final class KorbitService: BaseService, ServiceProtocol {
    let exchange: Exchange = .korbit

    init() {
        super.init(baseURL: Exchange.korbit.baseURL)
    }

    func fetchMarketPrices() -> Single<[MarketPrice]> {
        return request(endpoint: "/v2/tickers")
            .map { (response: KorbitTickerResponse) -> [MarketPrice] in
                response.toMarketPrices(exchange: self.exchange)
            }
    }
    
    func fetchMarketPrice(symbol: String) -> Single<[MarketPrice]> {
        let formattedSymbol = symbol.lowercased()
        return request(endpoint: "/v2/ticker?symbol=\(formattedSymbol)_krw")
            .map { (response: KorbitTickerResponse) -> [MarketPrice] in
                response.data.map { $0.toMarketPrice(exchange: self.exchange) }
            }
    }
    
    func fetchCandles(symbol: String, interval: CandleInterval, count: Int) -> Single<[Candle]> {
        let korbitSymbol = "\(symbol.lowercased())_krw"
        let korbitInterval = interval.korbitRawValue
        let endTimestamp = Int64(Date().timeIntervalSince1970 * 1000)

        return request(endpoint: "/v2/candles", queryParams: [
            "symbol": korbitSymbol,
            "interval": korbitInterval,
            "limit": "\(count)",
            "end": "\(endTimestamp)"
        ]).map { (response: KorbitCandleResponses) -> [Candle] in
            response.data.map { $0.toCandle(symbol: korbitSymbol) }
        }
    }
}

extension KorbitTickerResponse {
    func toMarketPrices(exchange: Exchange) -> [MarketPrice] {
        return self.data.map { $0.toMarketPrice(exchange: exchange) }
    }
}

extension KorbitTicker {
    func toMarketPrice(exchange: Exchange) -> MarketPrice {
        let priceChangePercent = Double(self.priceChangePercent) ?? 0
        let status = priceChangePercent > 0 ? "RISE" : (priceChangePercent == 0 ? "EVEN" : "FALL")

        return MarketPrice(
            symbol: self.symbol,
            price: Double(self.close) ?? 0,
            exchange: exchange.rawValue,
            change: status,
            changeRate: priceChangePercent,
            quoteVolume: Double(self.quoteVolume) ?? 0,
            highPrice: Double(self.high) ?? 0,
            lowPrice: Double(self.low) ?? 0
        )
    }
}

extension KorbitCandleResponse {
    func toCandle(symbol: String) -> Candle {
        return Candle(
            symbol: symbol,
            open: Double(self.open) ?? 0,
            close: Double(self.close) ?? 0,
            high: Double(self.high) ?? 0,
            low: Double(self.low) ?? 0,
            volume: Double(self.volume) ?? 0,
            quoteVolume: (Double(self.volume) ?? 0) * (Double(self.close) ?? 0),
            timestamp: self.timestamp
        )
    }
}

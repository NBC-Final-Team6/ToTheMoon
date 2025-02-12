//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

import Foundation
import RxSwift

final class UpbitService: BaseService, ServiceProtocol {
    let exchange: Exchange = .upbit

    init() {
        super.init(baseURL: Exchange.upbit.baseURL)
    }

    func fetchMarketPrices() -> Single<[MarketPrice]> {
        return request(endpoint: "/v1/ticker/all?quote_currencies=KRW")
            .map { (response: [UpbitTickerResponse]) -> [MarketPrice] in
                response.toMarketPrices(exchange: self.exchange)
            }
    }

    func fetchMarketPrice(symbol: String) -> Single<[MarketPrice]> {
        let formattedSymbol = symbol.uppercased()
        return request(endpoint: "/v1/ticker?markets=KRW-\(formattedSymbol)")
            .map { (response: [UpbitTickerResponse]) -> [MarketPrice] in
                response.toMarketPrices(exchange: self.exchange)
            }
    }

    func fetchCandles(symbol: String, interval: CandleInterval, count: Int) -> Single<[Candle]> {
        let intervalPath = interval.upbitAndBithumbRawValue
        let marketSymbol = "KRW-\(symbol.uppercased())"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let currentTime = Date()
        let toDate = dateFormatter.string(from: currentTime)
        
        return request(endpoint: "/v1/candles/\(intervalPath)?market=\(marketSymbol)&count=\(count)&to=\(toDate)")
            .map { (response: [UpbitCandleResponse]) -> [Candle] in
                response.toCandles()
            }
    }
}

extension Array where Element == UpbitTickerResponse {
    func toMarketPrices(exchange: Exchange) -> [MarketPrice] {
        return self.map { ticker in
            MarketPrice(
                symbol: ticker.market,
                price: ticker.tradePrice,
                exchange: exchange.rawValue,
                change: ticker.change,
                changeRate: ticker.changeRate * 100,
                quoteVolume: ticker.tradeVolume,
                highPrice: ticker.highPrice,
                lowPrice: ticker.lowPrice
            )
        }
    }
}

extension Array where Element == UpbitCandleResponse {
    func toCandles() -> [Candle] {
        return self.map { candle in
            Candle(
                symbol: candle.market,
                open: candle.open,
                close: candle.tradePrice,
                high: candle.high,
                low: candle.low,
                volume: candle.volume,
                quoteVolume: candle.quoteVolume,
                timestamp: candle.timestamp
            )
        }
    }
}


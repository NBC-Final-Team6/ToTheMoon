//
//  BithumbService.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

import Foundation
import RxSwift

final class BithumbService: BaseService {
    let exchange: Exchange = .bithumb

    init() {
        super.init(baseURL: Exchange.bithumb.baseURL)
    }

    func fetchMarketPrices() -> Single<[MarketPrice]> {
        return request(endpoint: "/public/ticker/ALL_KRW")
            .map { (response: BithumbTickersResponse) -> [MarketPrice] in
                response.data.toMarketPrices(exchange: self.exchange)
            }
    }

    func fetchAllMarkets() -> Single<[String]> {
        return request(endpoint: "/v1/market/all")
            .map { (response: [BithumbMarketResponse]) -> [String] in
                response.map { $0.market }
            }
    }

    func fetchMarketPrice(symbol: String) -> Single<[MarketPrice]> {
        let formattedSymbol = symbol.uppercased()
        return request(endpoint: "/v1/ticker?markets=KRW-\(formattedSymbol)")
            .map { (response: [BithumbTickerResponse]) -> [MarketPrice] in
                response.map { $0.toMarketPrice(exchange: self.exchange) }
            }
    }

    func fetchCandles(symbol: String, interval: CandleInterval, count: Int) -> Single<[Candle]> {
        let intervalPath = interval.upbitAndBithumbRawValue
        let marketSymbol = "KRW-\(symbol.uppercased())"
        return request(endpoint: "/v1/candles/\(intervalPath)?market=\(marketSymbol)&count=\(count)")
            .map { (response: [BithumbCandleResponse]) -> [Candle] in
                response.map { $0.toCandle() }
            }
    }
}

extension BithumbTickersResponse {
    func toMarketPrices(exchange: Exchange) -> [MarketPrice] {
        return self.data.toMarketPrices(exchange: exchange)
    }
}

extension BithumbTickersResponse.CoinDataWrapper {
    func toMarketPrices(exchange: Exchange) -> [MarketPrice] {
        return self.coins.map { symbol, data in
            MarketPrice(
                symbol: symbol,
                price: data.closingPrice,
                exchange: exchange.rawValue,
                change: data.fluctate24H >= 0 ? "RISE" : "FALL",
                changeRate: data.fluctateRate24H,
                quoteVolume: data.accTradeValue,
                highPrice: data.maxPrice,
                lowPrice: data.minPrice
            )
        }
    }
}

extension BithumbTickerResponse {
    func toMarketPrice(exchange: Exchange) -> MarketPrice {
        return MarketPrice(
            symbol: self.market,
            price: self.tradePrice,
            exchange: exchange.rawValue,
            change: self.change,
            changeRate: self.changeRate * 100,
            quoteVolume: self.tradeVolume,
            highPrice: self.highPrice,
            lowPrice: self.lowPrice
        )
    }
}

extension BithumbCandleResponse {
    func toCandle() -> Candle {
        return Candle(
            symbol: self.market,
            open: self.open,
            close: self.tradePrice,
            high: self.high,
            low: self.low,
            volume: self.volume,
            quoteVolume: self.quoteVolume,
            timestamp: self.timestamp
        )
    }
}

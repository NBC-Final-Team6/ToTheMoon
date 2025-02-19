//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/23/25.
//

import Foundation
import RxSwift

enum ChangeState: String {
    case rise = "RISE"
    case even = "EVEN"
    case fall = "FALL"
}

final class CoinOneService: BaseService, ServiceProtocol{
    let exchange: Exchange = .coinone

    init() {
        super.init(baseURL: Exchange.coinone.baseURL)
    }

    func fetchMarketPrices() -> Single<[MarketPrice]> {
        return request(endpoint: "/public/v2/ticker_new/KRW?additional_data=true")
            .map { (response: CoinOneTickerResponse) -> [MarketPrice] in
                response.tickers.map { $0.toMarketPrice(exchange: self.exchange) }
            }
    }

    func fetchMarketPrice(symbol: String) -> Single<[MarketPrice]> {
        let formattedSymbol = symbol.uppercased()
        return request(endpoint: "/public/v2/ticker_new/KRW/\(formattedSymbol)?additional_data=true")
            .map { (response: CoinOneTickerResponse) -> [MarketPrice] in
                response.tickers.map { $0.toMarketPrice(exchange: self.exchange) }
            }
    }

    func fetchCandles(symbol: String, interval: CandleInterval, count: Int) -> Single<[Candle]> {
        let intervalPath = interval.coinOneRawValue
        return request(endpoint: "/public/v2/chart/KRW/\(symbol)?interval=\(intervalPath)&size=\(count)")
            .map { (response: CoinOneCandleResponse) -> [Candle] in
                response.chart.map { $0.toCandle(symbol: symbol) }
            }
    }
}

extension Ticker {
    func toMarketPrice(exchange: Exchange) -> MarketPrice {
        let currentPrice = Double(self.last) ?? 0.0
        let yesterdayPrice = Double(self.yesterdayLast) ?? 0.0
        let changeRate = yesterdayPrice != 0 ? ((currentPrice - yesterdayPrice) / yesterdayPrice) * 100 : 0
        
        let change: ChangeState
        if changeRate > 0 {
            change = .rise
        } else if changeRate == 0 {
            change = .even
        } else {
            change = .fall
        }
        
        return MarketPrice(
            symbol: "\(self.quoteCurrency)-\(self.targetCurrency)",
            price: currentPrice,
            exchange: exchange.rawValue,
            change: change.rawValue,
            changeRate: changeRate,
            quoteVolume: Double(self.quoteVolume) ?? 0.0,
            highPrice: Double(self.high) ?? 0.0,
            lowPrice: Double(self.low) ?? 0.0
        )
    }
}

extension CoinOneCandle {
    func toCandle(symbol: String) -> Candle {
        return Candle(
            symbol: symbol,
            open: Double(self.open) ?? 0.0,
            close: Double(self.close) ?? 0.0,
            high: Double(self.high) ?? 0.0,
            low: Double(self.low) ?? 0.0,
            volume: Double(self.targetVolume) ?? 0.0,
            quoteVolume: Double(self.quoteVolume) ?? 0.0,
            timestamp: self.timestamp
        )
    }
}

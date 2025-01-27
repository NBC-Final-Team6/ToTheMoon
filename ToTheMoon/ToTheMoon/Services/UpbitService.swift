//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

import Foundation
import RxSwift

final class UpbitService {
    let exchange: Exchange = .upbit
    private let baseURL = Exchange.upbit.baseURL
    
    func fetchMarketPrices() -> Single<[MarketPrice]> {
        let endpoint = "\(baseURL)/v1/ticker/all?quote_currencies=KRW"
        guard let url = URL(string: endpoint) else {
            return Single.error(NetworkError.invalidUrl)
        }
        return NetworkManager.shared.fetch(url: url)
            .map { (response: [UpbitTickerResponse]) -> [MarketPrice] in
                return response.map { ticker in
                    MarketPrice(
                        symbol: ticker.market,
                        price: ticker.tradePrice,
                        exchange: self.exchange.rawValue,
                        change: ticker.change,
                        changeRate: ticker.changeRate,
                        quoteVolume: ticker.tradeVolume,
                        highPrice: ticker.highPrice,
                        lowPrice: ticker.lowPrice
                    )
                }
            }
    }
    
    func fetchCandles(symbol: String, interval: CandleInterval, count: Int) -> Single<[Candle]> {
        let intervalPath = interval.upbitAndBithumbRawValue
        let baseURL = Exchange.upbit.baseURL
        
        // `symbol`을 업비트 형식으로 변환 (예: "BTC" -> "KRW-BTC")
        let marketSymbol = "KRW-\(symbol.uppercased())"
        
        // 현재 시간 기준으로 UTC 형식의 `to` 파라미터 생성
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC 시간대
        let currentTime = Date()
        let toDate = dateFormatter.string(from: currentTime)
        
        // URL 생성
        let endpoint = "\(baseURL)/v1/candles/\(intervalPath)?market=\(marketSymbol)&count=\(count)&to=\(toDate)"
        
        guard let url = URL(string: endpoint) else {
            return Single.error(NetworkError.invalidUrl)
        }
        return NetworkManager.shared.fetch(url: url)
            .map { (response: [UpbitCandleResponse]) -> [Candle] in
                response.map { candle in
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
}


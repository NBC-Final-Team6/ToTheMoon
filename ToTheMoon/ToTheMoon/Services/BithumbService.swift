//
//  BithumbService.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

import Foundation
import RxSwift

final class BithumbService {
    let exchange: Exchange = .bithumb
    private let baseURL = Exchange.bithumb.baseURL
    
    func fetchMarketPrices() -> Single<[MarketPrice]> {
        let endpoint = "\(baseURL)/public/ticker/ALL_KRW"
        guard let url = URL(string: endpoint) else {
            return Single.error(NetworkError.invalidUrl)
        }
        return NetworkManager.shared.fetch(url: url)
            .map { (response: BithumbTickersResponse) -> [MarketPrice] in
                return response.data.coins.map { symbol, data in
                    // 현재 가격과 전날 가격
                    let currentPrice = Double(data.closingPrice)
                    let yesterdayPrice = Double(data.prevClosingPrice)
                    // changeRate 계산 (yesterdayPrice가 0인 경우 대비)
                    let changeRate = yesterdayPrice != 0 ? ((currentPrice - yesterdayPrice) / yesterdayPrice) * 100 : 0
                    // change 상태 결정
                    let change: ChangeState
                    if changeRate > 0 {
                        change = .rise
                    } else if changeRate == 0 {
                        change = .even
                    } else {
                        change = .fall
                    }
                    return MarketPrice(
                        symbol: symbol,
                        price: data.closingPrice,
                        exchange: self.exchange.rawValue,
                        change: change.rawValue,
                        changeRate: changeRate,
                        quoteVolume: data.accTradeValue,
                        highPrice: data.maxPrice,
                        lowPrice: data.minPrice
                    )
                }
            }
    }
    
    private func fetchAllMarkets() -> Single<[String]> {
        let endpoint = "\(baseURL)/v1/market/all"
        guard let url = URL(string: endpoint) else {
            return Single.error(NetworkError.invalidUrl)
        }

        return NetworkManager.shared.fetch(url: url)
            .map { (response: [BithumbMarketResponse]) -> [String] in
                // response 배열에서 각 객체의 market 값을 추출
                //print( response.map { $0.market } )
                return response.map { $0.market }
            }
    }
    
    func fetchMarketPrice(symbol: String) -> Single<[MarketPrice]> {
        let symbol = symbol.uppercased()
        let endpoint = "\(baseURL)/v1/ticker?markets=KRW-\(symbol)"
        guard let url = URL(string: endpoint) else {
            return Single.error(NetworkError.invalidUrl)
        }
        return NetworkManager.shared.fetch(url: url)
            .map { (response: [BithumbTickerResponse]) -> [MarketPrice] in
                return response.map { ticker in
                    MarketPrice(
                        symbol: ticker.market,
                        price: ticker.tradePrice,
                        exchange: self.exchange.rawValue,
                        change: ticker.change,
                        changeRate: ticker.changeRate * 100,
                        quoteVolume: ticker.tradeVolume,
                        highPrice: ticker.highPrice,
                        lowPrice: ticker.lowPrice
                    )
                }
            }
    }
    
    func fetchCandles(symbol: String, interval: CandleInterval, count: Int) -> Single<[Candle]> {
        let intervalPath = interval.upbitAndBithumbRawValue
        let baseURL = Exchange.bithumb.baseURL
        
        // `symbol`을 업비트 형식으로 변환 (예: "BTC" -> "KRW-BTC")
        let marketSymbol = "KRW-\(symbol.uppercased())"
        
        // 현재 시간 기준으로 UTC 형식의 `to` 파라미터 생성
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC 시간대
        let currentTime = Date()
        let toDate = dateFormatter.string(from: currentTime)
        
        let endpoint = "\(baseURL)/v1/candles/\(intervalPath)?market=\(marketSymbol)&count=\(count)&to=\(toDate)"
        
        guard let url = URL(string: endpoint) else {
            return Single.error(NetworkError.invalidUrl)
        }
        return NetworkManager.shared.fetch(url: url)
            .map { (response: [BithumbCandleResponse]) -> [Candle] in
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

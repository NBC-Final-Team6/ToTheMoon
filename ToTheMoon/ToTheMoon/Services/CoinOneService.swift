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

final class CoinOneService {
    let exchange: Exchange = .coinone
    lazy var baseURL = Exchange.coinone.baseURL
    
    func fetchMarketPrices() -> Single<[MarketPrice]> {
        let endpoint = "\(baseURL)/public/v2/ticker_new/KRW?additional_data=true"
        guard let url = URL(string: endpoint) else {
            return Single.error(NetworkError.invalidUrl)
        }
        return NetworkManager.shared.fetch(url: url)
            .do(onError: { error in
            }, onSubscribe: {
            })
            .map { (response: CoinOneTickerResponse) -> [MarketPrice] in
                return response.tickers.map { ticker in
                    // 현재 가격과 전날 가격
                    let currentPrice = Double(ticker.last) ?? 0
                    let yesterdayPrice = Double(ticker.yesterdayLast) ?? 0
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
                        symbol: "\(ticker.quoteCurrency)-\(ticker.targetCurrency)",
                        price: Double(ticker.last) ?? 0,
                        exchange: self.exchange.rawValue,
                        change: change.rawValue,
                        changeRate: changeRate,
                        quoteVolume: Double(ticker.quoteVolume) ?? 0,
                        highPrice: Double(ticker.high) ?? 0,
                        lowPrice: Double(ticker.low) ?? 0
                    )
                }
            }
    }
    
    func fetchCandles(symbol: String, interval: CandleInterval, count: Int) -> Single<[Candle]> {
        let baseURL = ExchangeEndpoint.coinone.baseURL
        let intervalPath = interval.coinOneRawValue // 코인원에서 지원하는 `1m`, `1d` 등
        let quoteCurrency = "KRW" // 코인원 기준 통화
        let targetCurrency = symbol // 종목 심볼 (예: BTC)

        let endpoint = "\(baseURL)/public/v2/chart/\(quoteCurrency)/\(targetCurrency)?interval=\(intervalPath)&size=\(count)"
        
        guard let url = URL(string: endpoint) else {
            return Single.error(NetworkError.invalidUrl)
        }
        
        return NetworkManager.shared.fetch(url: url)
            .map { (response: CoinOneCandleResponse ) -> [Candle] in
                response.chart.map { candle in
                    Candle(
                        symbol: targetCurrency,
                        open: Double(candle.open) ?? 0,
                        close: Double(candle.close) ?? 0,
                        high: Double(candle.high) ?? 0,
                        low: Double(candle.low) ?? 0,
                        volume: Double(candle.targetVolume) ?? 0,
                        quoteVolume: Double(candle.quoteVolume) ?? 0,
                        timestamp: candle.timestamp
                    )
                }
            }
    }
    
    
}

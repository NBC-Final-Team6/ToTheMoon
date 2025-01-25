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
        return fetchAllMarkets()
            .flatMap { markets -> Single<[MarketPrice]> in
                // markets에서 KRW-로 시작하는 심볼만 필터링
                let marketSymbols = markets.filter { $0.starts(with: "KRW-") }
                let tickerEndpoints = marketSymbols.map { "\(self.baseURL)/v1/ticker?markets=\($0)" }
                
                // 각 tickerEndpoint를 가져오는 Single 배열 생성
                let fetchTickers = tickerEndpoints.map { endpoint -> Single<[MarketPrice]> in
                    guard let url = URL(string: endpoint) else {
                        return Single.just([]) // URL이 잘못되었으면 빈 배열 반환
                    }
                    return NetworkManager.shared.fetch(url: url)
                        .do(onError: { error in
                        }, onSubscribe: {
                        })
                        .map { (responses: [BithumbTickerResponse]) -> [MarketPrice] in
                            // 응답을 MarketPrice 배열로 변환
                            return responses.map { response in
                                MarketPrice(
                                    symbol: response.market,
                                    price: response.tradePrice,
                                    exchange: self.exchange.rawValue,
                                    change: response.change,
                                    changeRate: response.changeRate,
                                    quoteVolume: response.tradeVolume,
                                    highPrice: response.highPrice,
                                    lowPrice: response.lowPrice
                                )
                            }
                        }
                        .catchAndReturn([]) // 에러 발생 시 빈 배열로 대체
                }
                
                // 모든 요청을 병렬로 실행한 뒤 결과를 단일 배열로 반환
                return Single.zip(fetchTickers)
                    .map { $0.flatMap { $0 } } // 중첩된 배열을 단일 배열로 변환
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
    
    func fetchCandles(symbol: String, interval: CandleInterval, count: Int) -> Single<[Candle]> {
        let intervalPath = interval.upbitAndBithumbRawValue
        let baseURL = ExchangeEndpoint.bithumb.baseURL
        
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

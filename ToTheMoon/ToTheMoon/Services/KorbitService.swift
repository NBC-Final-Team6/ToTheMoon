//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

import Foundation
import RxSwift

final class KorbitService {
    let exchange: Exchange = .korbit
    private let baseURL = ExchangeEndpoint.korbit.baseURL
    
    func fetchMarketPrices() -> Single<[MarketPrice]> {
        let endpoint = "\(baseURL)/v2/tickers"
        
        guard let url = URL(string: endpoint) else {
            return Single.error(NetworkError.invalidUrl)
        }
        return NetworkManager.shared.fetch(url: url)
            .do(onError: { error in
            }, onSubscribe: {
            })
            .map { (response: KorbitTickerResponse) -> [MarketPrice] in
                return response.data.map { ticker in
                    let priceChangePercent = Double(ticker.priceChangePercent) ?? 0
                    let status: String = priceChangePercent > 0 ? "RISE" : (priceChangePercent == 0 ? "EVEN" : "FALL")
                    
                    return MarketPrice(
                        symbol: ticker.symbol,
                        price: Double(ticker.close) ?? 0,
                        exchange: self.exchange.rawValue,
                        change: status,
                        changeRate: priceChangePercent,
                        quoteVolume: Double(ticker.quoteVolume) ?? 0,
                        highPrice: Double(ticker.high) ?? 0,
                        lowPrice: Double(ticker.low) ?? 0
                    )
                }
            }
    }
    
    func fetchCandles(symbol: String, interval: CandleInterval, count: Int) -> Single<[Candle]> {
        let baseURL = "https://api.korbit.co.kr/v2/candles"
        
        // `symbol` 코빗 형식 변환 (예: "BTC" -> "btc_krw")
        let korbitSymbol = "\(symbol.lowercased())_krw"
        
        // `interval` 코빗 형식 변환
        let korbitInterval = interval.korbitRawValue
        
        // URL 쿼리 파라미터 생성
        var queryItems = [
            URLQueryItem(name: "symbol", value: korbitSymbol),
            URLQueryItem(name: "interval", value: korbitInterval),
            URLQueryItem(name: "limit", value: String(count))
        ]
        
        // UTC 기준 `end` 타임스탬프 생성
        let currentTime = Date()
        let endTimestamp = Int64(currentTime.timeIntervalSince1970 * 1000)
        queryItems.append(URLQueryItem(name: "end", value: String(endTimestamp)))
        
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            return Single.error(NetworkError.invalidUrl)
        }
        
        return NetworkManager.shared.fetch(url: url)
            .map { (response: KorbitCandleResponses) -> [Candle] in
                response.data.map { candle in
                    Candle(
                        symbol: korbitSymbol,
                        open: Double(candle.open) ?? 0,
                        close: Double(candle.close) ?? 0,
                        high: Double(candle.high) ?? 0,
                        low: Double(candle.low) ?? 0,
                        volume: Double(candle.volume) ?? 0,
                        quoteVolume: (Double(candle.volume) ?? 0 * (Double(candle.close) ?? 0)),
                        timestamp: candle.timestamp
                    )
                }
            }
    }
}


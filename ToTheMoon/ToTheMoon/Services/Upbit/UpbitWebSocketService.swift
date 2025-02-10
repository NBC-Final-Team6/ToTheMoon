//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//

import Foundation
import RxSwift

final class UpbitWebSocketService {
    let exchange: Exchange = .upbit
    private let baseURL = "wss://api.upbit.com/websocket/v1"
    private let upbitService = UpbitService()
    private var cachedSymbols: [String] = []

    private func loadAllKrwSymbols() -> Single<[String]> {
        return upbitService.fetchMarketPrices()
            .map { markets in
                let krwMarkets = markets.filter { $0.symbol.hasPrefix("KRW-") }
                return krwMarkets.map { $0.symbol.replacingOccurrences(of: "KRW-", with: "") }
            }
            .do(onSuccess: { [weak self] symbols in
                self?.cachedSymbols = symbols
            })
    }

    func fetchAllKrwTickers() -> Observable<[MarketPrice]> {
        let symbolsObservable: Single<[String]> = cachedSymbols.isEmpty ? loadAllKrwSymbols() : .just(cachedSymbols)

        return symbolsObservable.asObservable()
            .flatMap { symbols -> Observable<UpbitWebSocketTickerResponse> in
                guard !symbols.isEmpty else {
                    return Observable.error(NetworkError.invalidData)
                }

                let requestPayload: [AnyEncodable] = [
                    AnyEncodable(["ticket": AnyEncodable("UNIQUE_TICKET_ID")]),
                    AnyEncodable([
                        "type": AnyEncodable("ticker"),
                        "codes": AnyEncodable(symbols.map { "KRW-\($0)" }.map { AnyEncodable($0) }),
                        "isOnlyRealtime": AnyEncodable(true)
                    ])
                ]

                return WebSocketManager.shared.connect(
                    to: URL(string: self.baseURL)!,
                    decodingType: UpbitWebSocketTickerResponse.self,  // ✅ UpbitWebSocketTickerResponse 사용
                    requestPayload: requestPayload
                )
            }
            .map { response in [response] }  // ✅ 단일 객체를 배열로 변환
            .map { responseArray in responseArray.toMarketPrices(exchange: self.exchange) } // ✅ MarketPrice 변환
    }
}

extension Array where Element == UpbitWebSocketTickerResponse {
    func toMarketPrices(exchange: Exchange) -> [MarketPrice] {
        return self.map { ticker in
            MarketPrice(
                symbol: ticker.code,
                price: ticker.tradePrice,
                exchange: exchange.rawValue,
                change: ticker.change,
                changeRate: ticker.changeRate * 100,
                quoteVolume: ticker.accTradeVolume,
                highPrice: ticker.highPrice,
                lowPrice: ticker.lowPrice
            )
        }
    }
}

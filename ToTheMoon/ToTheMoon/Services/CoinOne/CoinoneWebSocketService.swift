//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//

import Foundation
import RxSwift

final class CoinoneWebSocketService {
    let exchange: Exchange = .coinone
    private let baseURL = Exchange.coinone.webSocketURL
    private let coinoneService = CoinOneService()
    private var cachedSymbols: [String] = []
    private var webSocketDisposable: Disposable?

    private func loadAllKrwSymbols() -> Single<[String]> {
        return coinoneService.fetchMarketPrices()
            .map { marketPrices in
                let symbols = marketPrices.map { $0.symbol.uppercased().replacingOccurrences(of: "KRW-", with: "") }
                return symbols
            }
            .do(onSuccess: { [weak self] symbols in
                self?.cachedSymbols = symbols
            })
    }

    func fetchAllKrwTickers() -> Observable<[MarketPrice]> {
        let symbolsObservable: Single<[String]> = cachedSymbols.isEmpty ? loadAllKrwSymbols() : .just(cachedSymbols)

        return symbolsObservable.asObservable()
            .do(onNext: { symbols in
                self.connectWebSocket() // ✅ 웹소켓 연결 유지
                symbols.forEach { self.sendSubscribeMessage(for: $0) } // ✅ 심볼별로 메시지 전송
            })
            .flatMap { _ in WebSocketManager1.shared.connect(to: URL(string: self.baseURL)!) }
            .map { response in response.toMarketPrices(exchange: .coinone) }
    }

    private func connectWebSocket() {
        guard webSocketDisposable == nil else { return } // ✅ 이미 연결된 경우 중복 실행 방지

        webSocketDisposable = WebSocketManager1.shared.connect(
            to: URL(string: self.baseURL)!
        )
        .subscribe(onNext: { response in
            print("✅ 실시간 가격 업데이트: \(response.toMarketPrices(exchange: .coinone))")
        }, onError: { error in
            print("❌ WebSocket 오류: \(error)")
        })
    }

    private func sendSubscribeMessage(for symbol: String) {
        WebSocketManager1.shared.sendSubscribeMessage(symbol) // ✅ 기존 웹소켓을 통해 메시지만 전송
    }
}

extension CoinoneWebSocketResponse {
    func toMarketPrices(exchange: Exchange) -> [MarketPrice] {
        switch self {
        case .data(let tickerDataResponse):
            let tickerData = tickerDataResponse.data
            let formattedSymbol = "\(tickerData.quoteCurrency)-\(tickerData.targetCurrency)"
            let currentPrice = Double(tickerData.last) ?? 0.0
            let highPrice = Double(tickerData.high) ?? 0.0
            let lowPrice = Double(tickerData.low) ?? 0.0
            let quoteVolume = Double(tickerData.quoteVolume) ?? 0.0

            let yesterdayPrice = Double(tickerData.yesterdayLast) ?? 0.0
            let changeRate = yesterdayPrice != 0 ? ((currentPrice - yesterdayPrice) / yesterdayPrice) * 100 : 0
            let change: String = changeRate > 0 ? "RISE" : (changeRate < 0 ? "FALL" : "EVEN")

            return [
                MarketPrice(
                    symbol: formattedSymbol,
                    price: currentPrice,
                    exchange: exchange.rawValue,
                    change: change,
                    changeRate: changeRate,
                    quoteVolume: quoteVolume,
                    highPrice: highPrice,
                    lowPrice: lowPrice
                )
            ]

        default:
            return []
        }
    }
}

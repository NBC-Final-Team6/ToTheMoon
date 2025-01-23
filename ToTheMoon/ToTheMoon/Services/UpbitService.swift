//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

import Foundation
import RxSwift

final class UpbitService: KRWMarketPriceFetchable {
    let exchange = "Upbit"
    private let baseURL = ExchangeEndpoint.upbit.baseURL
    
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
                        exchange: self.exchange,
                        volume: ticker.tradeVolume,
                        highPrice: ticker.highPrice,
                        lowPrice: ticker.lowPrice
                    )
                }
            }
    }
}


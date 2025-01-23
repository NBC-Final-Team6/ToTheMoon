//
//  BithumbService.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

import Foundation
import RxSwift

final class BithumbService: KRWMarketPriceFetchable {
    let exchange = "Bithumb"
    private let baseURL = ExchangeEndpoint.upbit.baseURL
    
    func fetchMarketPrices() -> Single<[MarketPrice]> {
        let endpoint = "\(baseURL)/v1/ticker?markets=KRW-BTC"
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

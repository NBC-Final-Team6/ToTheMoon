//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/12/25.
//

import RxSwift

protocol ServiceProtocol {
    var exchange: Exchange { get }
    
    func fetchMarketPrices() -> Single<[MarketPrice]>
    func fetchMarketPrice(symbol: String) -> Single<[MarketPrice]>
    func fetchCandles(symbol: String, interval: CandleInterval, count: Int) -> Single<[Candle]>
}

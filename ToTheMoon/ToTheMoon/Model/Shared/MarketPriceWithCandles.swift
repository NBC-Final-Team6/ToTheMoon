//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/18/25.
//

import RxDataSources

struct MarketPriceWithCandles: IdentifiableType, Equatable {
    let marketPrice: MarketPrice
    let candles: [Candle]

    var identity: String {
            return "\(marketPrice.symbol)-\(marketPrice.exchange)"
        }

    static func == (lhs: MarketPriceWithCandles, rhs: MarketPriceWithCandles) -> Bool {
        return lhs.marketPrice == rhs.marketPrice && lhs.candles == rhs.candles
    }
}

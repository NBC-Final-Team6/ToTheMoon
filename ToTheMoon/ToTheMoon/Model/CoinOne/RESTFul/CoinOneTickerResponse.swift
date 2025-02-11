//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/23/25.
//

import Foundation

struct CoinOneTickerResponse: Decodable {
    let tickers: [Ticker]
}

struct Ticker: Decodable {
    let quoteCurrency: String
    let targetCurrency: String
    let high: String
    let low: String
    let last: String
    let yesterdayLast: String
    let quoteVolume: String

    enum CodingKeys: String, CodingKey {
        case quoteCurrency = "quote_currency"
        case targetCurrency = "target_currency"
        case yesterdayLast = "yesterday_last"
        case high
        case low
        case last
        case quoteVolume = "quote_volume"
    }
}


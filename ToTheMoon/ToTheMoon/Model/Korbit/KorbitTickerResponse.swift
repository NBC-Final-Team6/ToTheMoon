//
//  KorbitTickerResponse.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/23/25.
//

struct KorbitTicker: Decodable {
    let symbol: String
    let open: String
    let high: String
    let low: String
    let close: String
    let prevClose: String
    let priceChange: String
    let priceChangePercent: String
    let quoteVolume: String
}

struct KorbitTickerResponse: Decodable {
    let data: [KorbitTicker]
}

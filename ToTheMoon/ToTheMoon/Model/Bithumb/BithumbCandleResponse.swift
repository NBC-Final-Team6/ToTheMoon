//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/24/25.
//

struct BithumbCandleResponse: Decodable {
    let market: String
    let open: Double
    let tradePrice: Double
    let high: Double
    let low: Double
    let timestamp: Int64
    let volume: Double
    let quoteVolume: Double
    
    enum CodingKeys: String, CodingKey {
        case market
        case open = "opening_price"
        case tradePrice = "trade_price"
        case high = "high_price"
        case low = "low_price"
        case timestamp
        case volume = "candle_acc_trade_volume"
        case quoteVolume = "candle_acc_trade_price"
    }
}

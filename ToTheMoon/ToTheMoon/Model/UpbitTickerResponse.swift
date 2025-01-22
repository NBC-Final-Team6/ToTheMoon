//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

struct UpbitTickerResponse: Decodable {
    let market: String
    let tradePrice: Double
    let tradeVolume: Double
    let highPrice: Double
    let lowPrice: Double
    
    enum CodingKeys: String, CodingKey {
        case market
        case tradePrice = "trade_price"
        case tradeVolume = "trade_volume"
        case highPrice = "high_price"
        case lowPrice = "low_price"
    }
}

//
//  BithumbTickerResponse.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/23/25.
//

struct BithumbTickerResponse: Decodable {
    let market: String
    let tradePrice: Double
    let change: String
    let changeRate: Double
    let tradeVolume: Double
    let highPrice: Double
    let lowPrice: Double
    
    enum CodingKeys: String, CodingKey {
        case market
        case change
        case changeRate = "change_rate"
        case tradePrice = "trade_price"
        case tradeVolume = "acc_trade_price_24h"
        case highPrice = "high_price"
        case lowPrice = "low_price"
    }
}

struct BithumbTickerResponses: Decodable {
    let results: [BithumbTickerResponse]
}

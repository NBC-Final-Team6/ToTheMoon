//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

struct UpbitTickerResponse: Decodable {
    let market: String
    let tradePrice: Double
    
    enum CodingKeys: String, CodingKey {
        case market = "market"
        case tradePrice = "trade_price"
    }
}

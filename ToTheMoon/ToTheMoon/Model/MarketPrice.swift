//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

struct MarketPrice: Decodable {
    let symbol: String          // 티커 심볼
    let price: String           // 현재 가격
    let exchange: String        // 거래소 이름
    let volume: Double?         // 24시간 거래량 (옵션)
    let highPrice: Double?      // 24시간 최고가 (옵션)
    let lowPrice: Double?       // 24시간 최저가 (옵션)
}

struct Market: Codable {
    let market: String
    let koreanName: String?
    let englishName: String?
}

struct Ticker: Codable {
    let market: String
    let tradePrice: Double
    
    enum CodingKeys: String, CodingKey {
        case market
        case tradePrice = "trade_price"
    }
}

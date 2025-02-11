//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//

struct KorbitWebSocketResponse: Codable {
    let type: String
    let timestamp: Int
    let symbol: String
    let snapshot: Bool?
    let data: TickerData

    struct TickerData: Codable {
        let open: String
        let high: String
        let low: String
        let close: String
        let prevClose: String
        let priceChange: String
        let priceChangePercent: String
        let volume: String
        let quoteVolume: String
        let bestAskPrice: String
        let bestBidPrice: String
        let lastTradedAt: Int
    }
}

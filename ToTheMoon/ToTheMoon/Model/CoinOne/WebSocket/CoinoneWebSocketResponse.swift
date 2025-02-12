//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//

import Foundation

// WebSocket Response 타입 정의
enum CoinoneWebSocketResponse: Decodable {
    case connected(ConnectedResponse)
    case subscribed(SubscribedResponse)
    case data(TickerDataResponse)
    
    enum CodingKeys: String, CodingKey {
        case responseType = "response_type"
        case channel
        case data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let responseType = try container.decode(String.self, forKey: .responseType)
        
        switch responseType {
        case "CONNECTED":
            let data = try container.decode(ConnectedResponse.self, forKey: .data)
            self = .connected(data)
        case "SUBSCRIBED":
            let channel = try container.decode(String.self, forKey: .channel)
            let data = try container.decode(SubscriptionData.self, forKey: .data)
            self = .subscribed(SubscribedResponse(channel: channel, data: data))
        case "DATA":
            let channel = try container.decode(String.self, forKey: .channel)
            let data = try container.decode(TickerData.self, forKey: .data)
            self = .data(TickerDataResponse(channel: channel, data: data))
        default:
            throw DecodingError.dataCorruptedError(forKey: .responseType, in: container, debugDescription: "Unknown response type")
        }
    }
}

// CONNECTED 응답 모델
struct ConnectedResponse: Decodable {
    let sessionId: String
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
    }
}

// SUBSCRIBED 응답 모델
struct SubscribedResponse: Decodable {
    let channel: String
    let data: SubscriptionData
}

// SUBSCRIBED 내부 데이터
struct SubscriptionData: Decodable {
    let quoteCurrency: String
    let targetCurrency: String
    
    enum CodingKeys: String, CodingKey {
        case quoteCurrency = "quote_currency"
        case targetCurrency = "target_currency"
    }
}

// DATA 응답 모델
struct TickerDataResponse: Decodable {
    let channel: String
    let data: TickerData
}

// DATA 내부 데이터
struct TickerData: Decodable {
    let quoteCurrency: String
    let targetCurrency: String
    let timestamp: Int
    let quoteVolume: String
    let targetVolume: String
    let high: String
    let low: String
    let first: String
    let last: String
    let volumePower: String
    let askBestPrice: String
    let askBestQty: String
    let bidBestPrice: String
    let bidBestQty: String
    let id: String
    let yesterdayHigh: String
    let yesterdayLow: String
    let yesterdayFirst: String
    let yesterdayLast: String
    let yesterdayQuoteVolume: String
    let yesterdayTargetVolume: String

    enum CodingKeys: String, CodingKey {
        case quoteCurrency = "quote_currency"
        case targetCurrency = "target_currency"
        case timestamp
        case quoteVolume = "quote_volume"
        case targetVolume = "target_volume"
        case high, low, first, last
        case volumePower = "volume_power"
        case askBestPrice = "ask_best_price"
        case askBestQty = "ask_best_qty"
        case bidBestPrice = "bid_best_price"
        case bidBestQty = "bid_best_qty"
        case id
        case yesterdayHigh = "yesterday_high"
        case yesterdayLow = "yesterday_low"
        case yesterdayFirst = "yesterday_first"
        case yesterdayLast = "yesterday_last"
        case yesterdayQuoteVolume = "yesterday_quote_volume"
        case yesterdayTargetVolume = "yesterday_target_volume"
    }
}

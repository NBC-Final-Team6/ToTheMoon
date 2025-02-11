//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/24/25.
//

struct CoinOneCandle: Decodable {
    let timestamp: Int64
    let open: String
    let high: String
    let low: String
    let close: String
    let targetVolume: String
    let quoteVolume: String
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case open
        case high
        case low
        case close
        case targetVolume = "target_volume"
        case quoteVolume = "quote_volume"
    }
}

struct CoinOneCandleResponse: Decodable {
    let chart: [CoinOneCandle]
}

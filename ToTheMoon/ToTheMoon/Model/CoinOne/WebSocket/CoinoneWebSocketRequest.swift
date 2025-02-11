//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//

struct CoinoneWebSocketRequest: Encodable {
    let requestType: String
    let channel: String
    let topic: CoinoneTopic

    enum CodingKeys: String, CodingKey {
        case requestType = "request_type"
        case channel
        case topic
    }
}

struct CoinoneTopic: Encodable {
    let quoteCurrency: String
    let targetCurrency: String

    enum CodingKeys: String, CodingKey {
        case quoteCurrency = "quote_currency"
        case targetCurrency = "target_currency"
    }
}

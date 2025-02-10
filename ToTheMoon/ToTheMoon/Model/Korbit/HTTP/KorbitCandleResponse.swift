//
//  KorbitCandleResponse.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/24/25.
//

struct KorbitCandleResponse: Codable {
    let timestamp: Int64
    let open: String
    let high: String
    let low: String
    let close: String
    let volume: String
}

struct KorbitCandleResponses: Decodable {
    let data: [KorbitCandleResponse]
}

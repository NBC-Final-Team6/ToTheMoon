//
//  Market.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

struct Market: Decodable {
    let market: String
    let koreanName: String
    let englishName: String

    enum CodingKeys: String, CodingKey {
        case market
        case koreanName = "korean_name"
        case englishName = "english_name"
    }
}


//
//  KorbitMarketResponse.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/23/25.
//

import Foundation

struct market: Decodable {
    let symbol: String
    let status: String
}

struct KorbitMarketResponse: Decodable {
    let data: [market]
}

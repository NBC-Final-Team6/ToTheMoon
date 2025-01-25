//
//  KorbitMarketResponse.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/23/25.
//

import Foundation

// Model for individual item
struct market: Decodable {
    let symbol: String
    let status: String
}

// Model for root container
struct KorbitMarketResponse: Decodable {
    let data: [market]
}

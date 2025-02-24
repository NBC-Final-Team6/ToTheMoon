//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

import Foundation
import UIKit

struct SymbolID: Decodable {
    let id: String
    let symbol: String
    let name: String
}

struct SymbolData: Decodable {
    let id: String
    let symbol: String
    let name: String
    let image: SymbolImage?
    let description: Description
    let market_data: MarketData?
}

struct MarketData: Decodable {
    let market_cap: [String: Double]?
    let circulating_supply: Double?
    let max_supply: Double?
}

struct SymbolImage: Decodable {
    let thumb: String
}

struct Description: Decodable {
    let ko: String?
}

//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

struct MarketPrice: Decodable {
    let symbol: String
    let price: Double
    let exchange: String
    let volume: Double
    let highPrice: Double
    let lowPrice: Double
}

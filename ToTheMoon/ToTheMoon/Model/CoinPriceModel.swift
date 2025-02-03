//
//  CoinPriceModel.swift
//  ToTheMoon
//
//  Created by Jimin on 1/22/25.
//

import Foundation

struct MarketModel {
    let title: String
    let imageName: String
    
    static let items = [
        MarketModel(title: "업비트", imageName: "Upbit"),
        MarketModel(title: "빗썸", imageName: "Bithumb"),
        MarketModel(title: "코인원", imageName: "Coinone"),
        MarketModel(title: "코빗", imageName: "Korbit")
    ]
}

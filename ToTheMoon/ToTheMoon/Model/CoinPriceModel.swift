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
        MarketModel(title: "업비트", imageName: "1.circle"),
        MarketModel(title: "빗썸", imageName: "2.circle"),
        MarketModel(title: "코인원", imageName: "3.circle"),
        MarketModel(title: "코빗", imageName: "4.circle")
    ]
}

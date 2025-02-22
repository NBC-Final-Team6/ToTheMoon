//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/22/25.
//

import Foundation

struct PriceAlert: Codable {
    let exchange: String
    let coin: String
    let price: Double
    let condition: String // "above" or "below"
    let fcmToken: String
}

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
    let condition: String
    let fcmToken: String
}

struct PriceAlertWithID: Codable {
    let id: String
    let exchange: String
    let coin: String
    let price: Double
    let condition: String
    let fcmToken: String
}

struct RegisterResponse: Codable {
    let message: String
    let alert: PriceAlertWithID
}

struct AlertsResponse: Codable {
    let alerts: [PriceAlertWithID]
}

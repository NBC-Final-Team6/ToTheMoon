//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

import Foundation
import UIKit

struct Coin: Decodable {
    let id: String
    let symbol: String
    let name: String
    let image: CoinImage?
    let description: Description
}

struct CoinImage: Decodable {
    let thumb: String
}

struct Description: Decodable {
    let ko: String
}

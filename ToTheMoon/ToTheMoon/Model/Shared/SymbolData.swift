//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

import Foundation
import UIKit

struct SymbolData: Decodable {
    let id: String
    let symbol: String
    let name: String
    let image: SymbolImage?
    let description: Description
}

struct SymbolImage: Decodable {
    let thumb: String
}

struct Description: Decodable {
    let ko: String
}

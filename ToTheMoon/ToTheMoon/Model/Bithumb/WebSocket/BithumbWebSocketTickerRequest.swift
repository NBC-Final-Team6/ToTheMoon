//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//

import Foundation

struct BithumbWebSocketTickerRequest: Encodable {
    let type: String
    let symbols: [String]
    let tickTypes: [String]
}

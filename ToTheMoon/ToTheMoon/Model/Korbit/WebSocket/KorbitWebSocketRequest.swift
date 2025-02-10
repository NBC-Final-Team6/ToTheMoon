//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//
import Foundation

struct KorbitWebSocketRequest: Encodable {
    let method: String
    let type: String
    let symbols: [String]
}

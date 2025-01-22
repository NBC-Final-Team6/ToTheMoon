//
//  APIEndpoint.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

import Foundation

enum ExchangeEndpoint: String {
    case upbit = "https://api.upbit.com"
    case bithumb = "https://api.bithumb.com"
    case coinone = "https://api.coinone.co.kr"
    case korbit = "https://api.korbit.co.kr"
    case gopax = "https://api.gopax.co.kr"

    var baseURL: String {
        return self.rawValue
    }
}

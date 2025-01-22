//
//  APIEndpoint.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

import Foundation

enum APIEndpoint {
    // 거래소별 엔드포인트
    enum Exchange {
        static let binance = "https://api.binance.com/api/v3"
        static let coinbase = "https://api.coinbase.com/v2"
        static let kraken = "https://api.kraken.com/0/public"
        static let upbit = "https://api.upbit.com/v1"
        static let bitfinex = "https://api.bitfinex.com/v1"
        static let huobi = "https://api.huobi.pro"
    }
}

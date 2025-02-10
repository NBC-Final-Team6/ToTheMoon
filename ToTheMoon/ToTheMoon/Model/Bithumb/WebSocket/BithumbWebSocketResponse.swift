//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//

import Foundation

// 빗썸 웹소켓 응답의 기본 구조
struct BithumbWebSocketTickerResponse: Decodable {
    let status: String?
    let resmsg: String?
    let type: String?
    let timestamp: String?
    let content: ContentData?

    struct ContentData: Decodable {
        let symbol: String
        let tickType: String
        let date: String
        let time: String
        let openPrice: String
        let closePrice: String
        let lowPrice: String
        let highPrice: String
        let value: String
        let volume: String
        let sellVolume: String
        let buyVolume: String
        let prevClosePrice: String
        let chgRate: String
        let chgAmt: String
        let volumePower: String
    }
}

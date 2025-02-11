//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//

import Foundation

struct UpbitWebSocketTickerResponse: Decodable {
    let type: String             // 데이터 타입 (예: "ticker")
    let code: String             // 종목 코드 (예: "KRW-BTC")
    let openingPrice: Double     // 시가
    let highPrice: Double        // 고가
    let lowPrice: Double         // 저가
    let tradePrice: Double       // 현재가
    let prevClosingPrice: Double // 전일 종가
    let accTradePrice: Double    // 누적 거래 대금
    let change: String           // 전일 대비 (예: "RISE", "FALL")
    let changePrice: Double      // 변화량
    let signedChangePrice: Double // 절대 변화량
    let changeRate: Double       // 변동률
    let signedChangeRate: Double // 절대 변동률
    let tradeVolume: Double      // 체결량
    let accTradeVolume: Double   // 누적 체결량
    let accAskVolume: Double     // 누적 매도량
    let accBidVolume: Double     // 누적 매수량
    let highest52WeekPrice: Double  // 52주 최고가
    let highest52WeekDate: String   // 52주 최고가 날짜
    let lowest52WeekPrice: Double   // 52주 최저가
    let lowest52WeekDate: String    // 52주 최저가 날짜
    let timestamp: Int           // 데이터 생성 타임스탬프
    let accTradePrice24h: Double // 24시간 누적 거래 대금
    let accTradeVolume24h: Double // 24시간 누적 거래량

    enum CodingKeys: String, CodingKey {
        case type, code, change, timestamp
        case openingPrice = "opening_price"
        case highPrice = "high_price"
        case lowPrice = "low_price"
        case tradePrice = "trade_price"
        case prevClosingPrice = "prev_closing_price"
        case accTradePrice = "acc_trade_price"
        case changePrice = "change_price"
        case signedChangePrice = "signed_change_price"
        case changeRate = "change_rate"
        case signedChangeRate = "signed_change_rate"
        case tradeVolume = "trade_volume"
        case accTradeVolume = "acc_trade_volume"
        case accAskVolume = "acc_ask_volume"
        case accBidVolume = "acc_bid_volume"
        case highest52WeekPrice = "highest_52_week_price"
        case highest52WeekDate = "highest_52_week_date"
        case lowest52WeekPrice = "lowest_52_week_price"
        case lowest52WeekDate = "lowest_52_week_date"
        case accTradePrice24h = "acc_trade_price_24h"
        case accTradeVolume24h = "acc_trade_volume_24h"
    }
}

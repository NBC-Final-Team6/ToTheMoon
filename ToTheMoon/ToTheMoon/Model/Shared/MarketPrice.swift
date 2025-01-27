//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

import Foundation

struct MarketPrice: Decodable {
    let symbol: String       // 심볼(종목) 이름, 예: "BTC" (비트코인), "ETH" (이더리움)
    let price: Double        // 현재 시장 가격
    let exchange: String     // 거래소 이름, 예: "Upbit", "Bithumb"
    let change: String       // 가격 변화 방향, 예: "RISE" (상승), "FALL" (하락), "EVEN" (변화 없음)
    let changeRate: Double   // 가격 변화율 (소수점 비율, 예: 0.05는 5% 상승)
    let quoteVolume: Double  // 최근 24시간 동안의 거래량 거래 금액 (기준 통화로 표시, 예: KRW)
    let highPrice: Double    // 최근 24시간 동안의 최고 거래 가격
    let lowPrice: Double     // 최근 24시간 동안의 최저 거래 가격
}

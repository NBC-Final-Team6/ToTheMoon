//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/24/25.
//

import Foundation

struct Candle {
    let symbol: String         // 심볼(종목) 이름, 예: "BTC" (비트코인), "ETH" (이더리움)
    let open: Double           // 해당 시간 간격(캔들)의 시작 가격
    let close: Double          // 해당 시간 간격(캔들)의 종료 가격
    let high: Double           // 해당 시간 간격(캔들) 동안의 최고 가격
    let low: Double            // 해당 시간 간격(캔들) 동안의 최저 가격
    let volume: Double         // 해당 시간 간격(캔들) 동안의 거래량 (자산의 양)
    let quoteVolume: Double    // 해당 시간 간격(캔들) 동안의 거래 금액 (기준 통화로 표시, 예: KRW)
    let timestamp: Int64       // 캔들이 생성된 시간(유닉스 타임스탬프, 밀리초 또는 초 단위)
}

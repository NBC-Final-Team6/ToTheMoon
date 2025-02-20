//
//  Untitled 2.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/20/25.
//

import Foundation

struct CoinAlarm: Codable {
    let coin: String
    let targetPrice: Double
    let isHigher: Bool // true: 상승 시 알람, false: 하락 시 알람
}

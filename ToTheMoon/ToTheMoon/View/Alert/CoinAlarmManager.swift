//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/20/25.
//

import Foundation

class CoinAlarmManager {
    static let shared = CoinAlarmManager()
    private let key = "coinAlarms"

    func saveAlarms(_ alarms: [CoinAlarm]) {
        if let data = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func loadAlarms() -> [CoinAlarm] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let alarms = try? JSONDecoder().decode([CoinAlarm].self, from: data) else {
            return []
        }
        return alarms
    }
}

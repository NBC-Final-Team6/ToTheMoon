//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/20/25.
//

import Firebase
import FirebaseFirestore

class FirestoreAlertManager {
    static let shared = FirestoreAlertManager()

    func setPriceAlert(exchange: String, symbol: String, targetPrice: Double) {
        let db = Firestore.firestore()
        let alertRef = db.collection("price_alerts").document("\(exchange)_\(symbol)")

        alertRef.setData([
            "exchange": exchange,
            "symbol": symbol,
            "targetPrice": targetPrice,
            "timestamp": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("❌ 알림 등록 실패: \(error)")
            } else {
                print("✅ 가격 알림 등록 성공!")
            }
        }
    }
}

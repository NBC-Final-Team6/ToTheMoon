//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/22/25.
//

import Foundation

final class PriceAlertManager {
    static let shared = PriceAlertManager()
    
    private let serverURL = "http://서버주소:3000/alerts" // 🔹 서버 주소를 입력하세요
    
    func registerPriceAlert(exchange: String, coin: String, price: Double, condition: String) {
        guard let fcmToken = UserDefaults.standard.string(forKey: "fcmToken") else {
            print("❌ FCM 토큰을 찾을 수 없음")
            return
        }
        
        // 요청 데이터 구성
        let parameters: [String: Any] = [
            "exchange": exchange,
            "coin": coin,
            "price": price,
            "condition": condition, // "above" or "below"
            "fcmToken": fcmToken
        ]
        
        // JSON 변환
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            print("❌ JSON 변환 실패")
            return
        }
        
        // URL 설정
        guard let url = URL(string: serverURL) else {
            print("❌ 잘못된 URL")
            return
        }
        
        // URLRequest 설정
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // URLSession 요청 실행
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 알림 등록 실패: \(error.localizedDescription)")
                return
            }
            
            // 응답 데이터 처리
            if let data = data {
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                    print(" 알림 등록 성공: \(jsonResponse)")
                } catch {
                    print("❌ JSON 응답 처리 실패: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume() // 요청 시작
    }
}

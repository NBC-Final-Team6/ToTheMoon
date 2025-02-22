//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/22/25.
//

import Foundation
import RxSwift
import RxCocoa

final class PriceAlertManager {
    static let shared = PriceAlertManager()
    
    private let serverURL = "http://서버주소:3000/alerts" // 서버 주소 변경 필요
    
    /// 지정가 알림 요청을 처리하는 함수
    func registerPriceAlert(exchange: String, coin: String, price: Double, condition: String, fcmToken: String) -> Observable<Result<String, Error>> {
        
        return Observable.create { observer in
            let parameters: [String: Any] = [
                "exchange": exchange,
                "coin": coin,
                "price": price,
                "condition": condition, // "above" or "below"
                "fcmToken": fcmToken
            ]
            
            // JSON 변환
            guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
                observer.onNext(.failure(NSError(domain: "JSON Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "❌ JSON 변환 실패"])))
                observer.onCompleted()
                return Disposables.create()
            }
            
            // URL 설정
            guard let url = URL(string: self.serverURL) else {
                observer.onNext(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: [NSLocalizedDescriptionKey: "❌ 잘못된 URL"])))
                observer.onCompleted()
                return Disposables.create()
            }
            
            // URLRequest 설정
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            // URLSession을 Rx로 변환하여 실행
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    observer.onNext(.failure(error))
                } else if let data = data {
                    do {
                        let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                        print("알림 등록 성공: \(jsonResponse)")
                        observer.onNext(.success("알림 등록 완료"))
                    } catch {
                        observer.onNext(.failure(error))
                    }
                }
                observer.onCompleted()
            }
            
            task.resume()
            return Disposables.create { task.cancel() }
        }
    }
}

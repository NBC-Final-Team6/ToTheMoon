//
//  AlarmEditViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/22/25.
//

import Foundation
import RxSwift
import RxCocoa

final class AlarmEditViewModel {
    
    // ✅ 서버 URL (변경 필요)
    private let serverURL = "http://서버주소:3000/alerts"

    // ✅ 네트워크 응답을 전달할 Observable
    let alertRegistrationResult = PublishSubject<Result<String, Error>>()
    
    // ✅ Dispose Bag (Rx 메모리 관리)
    private let disposeBag = DisposeBag()

    /// 지정가 알람 등록 요청
    func registerPriceAlert(exchange: String, coin: String, price: Double, condition: String) {
        guard let fcmToken = UserDefaults.standard.string(forKey: "fcmToken") else {
            alertRegistrationResult.onNext(.failure(NSError(domain: "FCM Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "❌ FCM 토큰 없음"])))
            return
        }
        
        let parameters: [String: Any] = [
            "exchange": exchange,
            "coin": coin,
            "price": price,
            "condition": condition, // "above" or "below"
            "fcmToken": fcmToken
        ]
        
        // JSON 변환
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            alertRegistrationResult.onNext(.failure(NSError(domain: "JSON Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "❌ JSON 변환 실패"])))
            return
        }
        
        // URL 설정
        guard let url = URL(string: serverURL) else {
            alertRegistrationResult.onNext(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: [NSLocalizedDescriptionKey: "❌ 잘못된 URL"])))
            return
        }
        
        // URLRequest 설정
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // ✅ Rx를 활용한 네트워크 요청
        URLSession.shared.rx.response(request: request)
            .subscribe(onNext: { [weak self] response, data in
                guard let self = self else { return }
                
                if response.statusCode == 201 {
                    do {
                        let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                        print("✅ 알림 등록 성공: \(jsonResponse)")
                        self.alertRegistrationResult.onNext(.success("✅ 알림 등록 완료"))
                    } catch {
                        self.alertRegistrationResult.onNext(.failure(error))
                    }
                } else {
                    let error = NSError(domain: "Server Error", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: "❌ 서버 응답 오류 (\(response.statusCode))"])
                    self.alertRegistrationResult.onNext(.failure(error))
                }
            }, onError: { [weak self] error in
                self?.alertRegistrationResult.onNext(.failure(error))
            })
            .disposed(by: disposeBag)
    }
}

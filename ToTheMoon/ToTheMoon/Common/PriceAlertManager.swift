//
//  PriceAlertManager.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/22/25.
//

import Foundation
import RxSwift

final class PriceAlertManager {
    static let shared = PriceAlertManager()
    
    private let serverURL = "https://tothemoonserver-production.up.railway.app/alerts" // 서버 주소를 입력하세요
    
    /// 지정가 알림 요청
    func registerPriceAlert(alert: PriceAlert) -> Observable<Result<String, Error>> {
        guard let jsonData = try? JSONEncoder().encode(alert) else {
            return Observable.just(.failure(NSError(
                domain: "JSON Error",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "JSON 변환 실패"]
            )))
        }
        
        guard let url = URL(string: serverURL) else {
            return Observable.just(.failure(NSError(
                domain: "Invalid URL",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "잘못된 URL"]
            )))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        return URLSession.shared.rx.response(request: request)
            .map { response, data in
                if response.statusCode == 201 {
                    return .success("알림 등록 완료")
                } else {
                    return .failure(NSError(
                        domain: "Server Error",
                        code: response.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "서버 응답 오류 (\(response.statusCode))"]
                    ))
                }
            }
            .catch { error in
                Observable.just(.failure(error))
            }
    }
}

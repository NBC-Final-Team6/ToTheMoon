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
    
    //private let serverURL = "https://tothemoonserver-production.up.railway.app/alerts" // 서버 주소를 입력하세요
    private let serverURL = "https://d05e-222-111-120-108.ngrok-free.app/alerts" // 서버 주소를 입력하세요
    
    /// 지정가 알림 등록 요청 (서버에서 `id` 반환)
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
            
            return URLSession.shared.rx.data(request: request)
                .map { data in
                    if let response = try? JSONDecoder().decode(RegisterResponse.self, from: data) {
                        return .success(response.alert.id) // 서버에서 받은 `id` 반환
                    } else {
                        return .failure(NSError(
                            domain: "Parsing Error",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "서버 응답을 파싱할 수 없음"]
                        ))
                    }
                }
                .catch { error in
                    Observable.just(.failure(error))
                }
        }
        
        /// 등록된 알림 전체 조회
        func fetchPriceAlerts() -> Observable<Result<[PriceAlertWithID], Error>> {
            guard let url = URL(string: serverURL) else {
                return Observable.just(.failure(NSError(
                    domain: "Invalid URL",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "잘못된 URL"]
                )))
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            return URLSession.shared.rx.data(request: request)
                .map { data in
                    if let response = try? JSONDecoder().decode(AlertsResponse.self, from: data) {
                        return .success(response.alerts)
                    } else {
                        return .failure(NSError(
                            domain: "Parsing Error",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "서버 응답을 파싱할 수 없음"]
                        ))
                    }
                }
                .catch { error in
                    Observable.just(.failure(error))
                }
        }

        /// 지정가 알림 삭제 요청 (ID 기반 삭제)
        func deletePriceAlert(alertID: String) -> Observable<Result<String, Error>> {
            let deleteURL = "\(serverURL)/\(alertID)" // 특정 ID 기반 삭제 요청
            
            guard let url = URL(string: deleteURL) else {
                return Observable.just(.failure(NSError(
                    domain: "Invalid URL",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "잘못된 URL"]
                )))
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            return URLSession.shared.rx.response(request: request)
                .map { response, data in
                    if response.statusCode == 200 {
                        return .success("알림 삭제 완료")
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

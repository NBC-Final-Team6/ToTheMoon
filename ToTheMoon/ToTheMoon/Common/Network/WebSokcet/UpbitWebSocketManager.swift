//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/8/25.
//

import Foundation
import Starscream
import RxSwift

final class UpbitWebSocketManager: BaseWebSocketManager {
    static let shared = UpbitWebSocketManager()
    
    private override init() {
        super.init()
    }

    override func handleWebSocketEvent<T: Decodable>(event: WebSocketEvent, observer: AnyObserver<T>) {
        switch event {
        case .binary(let data):
            print("📥 WebSocket 응답 수신 (Binary Data): \(data.count) bytes")
            decodeBinaryResponse(data, decodingType: T.self, observer: observer)
        
        default:
            super.handleWebSocketEvent(event: event, observer: observer) // 🔹 부모 클래스의 로직도 실행
        }
    }
    
    private func decodeBinaryResponse<T: Decodable>(_ data: Data, decodingType: T.Type, observer: AnyObserver<T>) {
        do {
            guard let jsonString = String(data: data, encoding: .utf8) else {
                throw WebSocketError.decodingFailed(NSError(domain: "BinaryToString", code: -1, userInfo: [NSLocalizedDescriptionKey: "바이너리 데이터를 UTF-8 문자열로 변환할 수 없습니다."]))
            }
            print("📝 변환된 JSON 문자열: \(jsonString)")

            guard let jsonData = jsonString.data(using: .utf8) else {
                throw WebSocketError.decodingFailed(NSError(domain: "StringToJSON", code: -1, userInfo: [NSLocalizedDescriptionKey: "UTF-8 문자열을 JSON 데이터로 변환할 수 없습니다."]))
            }

            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])

            if let dict = jsonObject as? [String: Any] {
                print("📌 JSON 형식: 딕셔너리 (Dictionary)")
                let decodedObject = try JSONDecoder().decode(T.self, from: jsonData)
                observer.onNext(decodedObject)

            } else if let array = jsonObject as? [[String: Any]] {
                print("📌 JSON 형식: 배열 (Array)")
                let decodedArray = try JSONDecoder().decode([T].self, from: jsonData)
                for item in decodedArray {
                    observer.onNext(item)
                }
            } else {
                throw WebSocketError.decodingFailed(NSError(domain: "InvalidJSONFormat", code: -1, userInfo: [NSLocalizedDescriptionKey: "예상치 못한 JSON 형식입니다."]))
            }
        } catch {
            print("❌ Binary WebSocket 응답 디코딩 실패: \(error.localizedDescription)")
            observer.onError(WebSocketError.decodingFailed(error))
        }
    }
}

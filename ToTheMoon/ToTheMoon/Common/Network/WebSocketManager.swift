//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/8/25.
//

import Foundation
import Starscream
import RxSwift

final class WebSocketManager {
    static let shared = WebSocketManager()
    private var socket: WebSocket?
    private var disposeBag = DisposeBag()
    private var requestString: String?

    private init() {}

    func connect<T: Decodable, U: Encodable>(to url: URL, decodingType: T.Type, requestPayload: U) -> Observable<T> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(WebSocketError.managerDeinitialized)
                return Disposables.create()
            }

            let request = URLRequest(url: url, timeoutInterval: 5)
            self.socket = WebSocket(request: request)

            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            if let jsonData = try? encoder.encode(requestPayload),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                self.requestString = jsonString
            } else {
                observer.onError(WebSocketError.encodingFailed)
                return Disposables.create()
            }

            self.socket?.onEvent = { event in
                switch event {
                case .connected:
                    print("✅ WebSocket 연결 성공")
                    if let requestString = self.requestString {
                        self.sendMessage(requestString)
                    }

                case .disconnected(let reason, _):
                    print("⚠️ WebSocket 연결 해제됨: \(reason)")
                    observer.onError(WebSocketError.connectionFailed(NSError(domain: "WebSocketDisconnected", code: -1, userInfo: [NSLocalizedDescriptionKey: reason])))

                case .text(let text):
                    print("📥 WebSocket 응답 수신: \(text)")
                    do {
                        let data = text.data(using: .utf8) ?? Data()
                        let decodedObject = try JSONDecoder().decode(T.self, from: data)
                        observer.onNext(decodedObject)
                    } catch {
                        print("❌ WebSocket 응답 디코딩 실패: \(error.localizedDescription)")
                        print("❌ 디코딩 실패한 데이터: \(text)")
                        observer.onError(WebSocketError.decodingFailed(error))
                    }

                case .binary(let data):
                    print("📥 WebSocket 응답 수신 (Binary Data): \(data.count) bytes")
                    self.decodeBinaryResponse(data, decodingType: decodingType, observer: observer)

                case .error(let error):
                    if let error = error {
                        print("❌ WebSocket 연결 에러: \(error.localizedDescription)")
                        observer.onError(WebSocketError.connectionFailed(error))
                    }
                default:
                    break
                }
            }

            self.socket?.connect()

            return Disposables.create {
                self.socket?.disconnect()
                self.socket = nil
                print("❌ WebSocket 연결 해제")
            }
        }
    }
    
    func sendMessage(_ message: String) {
        socket?.write(string: message, completion: {
            print("📤 WebSocket 메시지 전송 성공: \(message)")
        })
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

            if let dict = jsonObject as? [String: Any] {  // 🔹 JSON이 딕셔너리일 경우
                print("📌 JSON 형식: 딕셔너리 (Dictionary)")

                // 🔹 직접 T로 디코딩
                let decodedObject = try JSONDecoder().decode(T.self, from: jsonData)
                observer.onNext(decodedObject) // ✅ T 타입으로 변환 후 전달

            } else if let array = jsonObject as? [[String: Any]] {  // 🔹 JSON이 배열일 경우
                print("📌 JSON 형식: 배열 (Array)")

                // 🔹 배열을 [T]로 변환
                let decodedArray = try JSONDecoder().decode([T].self, from: jsonData)
                
                // 🔥 배열을 직접 observer에 전달할 수 없으므로 개별 요소를 전달
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

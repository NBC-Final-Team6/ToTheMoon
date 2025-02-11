//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/11/25.
//

import Foundation
import Starscream
import RxSwift

final class KorbitWebSocketManager {
    static let shared = KorbitWebSocketManager()
    private var socket: WebSocket?
    private var disposeBag = DisposeBag()
    private var requestString: String? // ✅ 요청할 데이터 (String) 저장

    private init() {}

    /// **WebSocket 연결 함수**
    func connect<T: Decodable, U: Encodable>(to url: URL, decodingType: T.Type, requestPayload: U) -> Observable<T> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(WebSocketError.managerDeinitialized)
                return Disposables.create()
            }

            let request = URLRequest(url: url, timeoutInterval: 5)
            self.socket = WebSocket(request: request)

            // ✅ JSONEncoder를 사용하여 JSON 문자열 변환
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
                        self.sendMessage(requestString) // ✅ 연결되면 즉시 메시지 전송
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

    /// **WebSocket 메시지 전송 (String)**
    func sendMessage(_ message: String) {
        socket?.write(string: message, completion: {
            print("📤 WebSocket 메시지 전송 성공: \(message)")
        })
    }
}

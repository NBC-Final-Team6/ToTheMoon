////
////  Untitled.swift
////  ToTheMoon
////
////  Created by 황석범 on 2/11/25.
////
//
//import Foundation
//import Starscream
//import RxSwift
//
//class BaseWebSocketManager {
//    var socket: WebSocket?
//    var disposeBag = DisposeBag()
//    var requestString: String?
//    
//    func connect<T: Decodable, U: Encodable>(to url: URL, decodingType: T.Type, requestPayload: U) -> Observable<T> {
//        return Observable.create { [weak self] observer in
//            guard let self = self else {
//                observer.onError(WebSocketError.managerDeinitialized)
//                return Disposables.create()
//            }
//            
//            let request = URLRequest(url: url, timeoutInterval: 5)
//            self.socket = WebSocket(request: request)
//
//            if let jsonData = try? JSONEncoder().encode(requestPayload),
//               let jsonString = String(data: jsonData, encoding: .utf8) {
//                self.requestString = jsonString
//            } else {
//                observer.onError(WebSocketError.encodingFailed)
//                return Disposables.create()
//            }
//
//            self.socket?.onEvent = { [weak self] event in
//                self?.handleWebSocketEvent(event: event, observer: observer)
//            }
//
//            self.socket?.connect()
//
//            return Disposables.create {
//                self.socket?.disconnect()
//                self.socket = nil
//                print("❌ WebSocket 연결 해제")
//            }
//        }
//    }
//
//    func sendMessage(_ message: String) {
//        socket?.write(string: message, completion: {
//            print("📤 WebSocket 메시지 전송 성공: \(message)")
//        })
//    }
//
//    func handleWebSocketEvent<T: Decodable>(event: WebSocketEvent, observer: AnyObserver<T>) {
//        switch event {
//        case .connected:
//            print("✅ WebSocket 연결 성공")
//            if let requestString = requestString {
//                sendMessage(requestString)
//            }
//            
//        case .text(let text):
//            print("📥 WebSocket 응답 수신: \(text)")
//            do {
//                let data = text.data(using: .utf8) ?? Data()
//                let decodedObject = try JSONDecoder().decode(T.self, from: data)
//                observer.onNext(decodedObject)
//            } catch {
//                print("❌ WebSocket 응답 디코딩 실패: \(error.localizedDescription)")
//                observer.onError(WebSocketError.decodingFailed(error))
//            }
//            
//        case .error(let error):
//            if let error = error {
//                print("❌ WebSocket 연결 에러: \(error.localizedDescription)")
//                observer.onError(WebSocketError.connectionFailed(error))
//            }
//            
//        case .disconnected(let reason, _):
//            print("⚠️ WebSocket 연결 해제됨: \(reason)")
//            observer.onError(WebSocketError.connectionFailed(NSError(
//                domain: "WebSocketDisconnected",
//                code: -1,
//                userInfo: [NSLocalizedDescriptionKey: reason]
//            )))
//        default:
//            break
//        }
//    }
//}
//
//final class UpbitWebSocketManager: BaseWebSocketManager {
//    static let shared = UpbitWebSocketManager()
//    
//    private override init() {
//        super.init()
//    }
//
//    override func handleWebSocketEvent<T: Decodable>(event: WebSocketEvent, observer: AnyObserver<T>) {
//        switch event {
//        case .binary(let data):
//            print("📥 WebSocket 응답 수신 (Binary Data): \(data.count) bytes")
//            decodeBinaryResponse(data, decodingType: T.self, observer: observer)
//        
//        default:
//            super.handleWebSocketEvent(event: event, observer: observer) // 🔹 부모 클래스의 로직도 실행
//        }
//    }
//    
//    private func decodeBinaryResponse<T: Decodable>(_ data: Data, decodingType: T.Type, observer: AnyObserver<T>) {
//        do {
//            guard let jsonString = String(data: data, encoding: .utf8) else {
//                throw WebSocketError.decodingFailed(NSError(domain: "BinaryToString", code: -1, userInfo: [NSLocalizedDescriptionKey: "바이너리 데이터를 UTF-8 문자열로 변환할 수 없습니다."]))
//            }
//            print("📝 변환된 JSON 문자열: \(jsonString)")
//
//            guard let jsonData = jsonString.data(using: .utf8) else {
//                throw WebSocketError.decodingFailed(NSError(domain: "StringToJSON", code: -1, userInfo: [NSLocalizedDescriptionKey: "UTF-8 문자열을 JSON 데이터로 변환할 수 없습니다."]))
//            }
//
//            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
//
//            if let dict = jsonObject as? [String: Any] {
//                print("📌 JSON 형식: 딕셔너리 (Dictionary)")
//                let decodedObject = try JSONDecoder().decode(T.self, from: jsonData)
//                observer.onNext(decodedObject)
//
//            } else if let array = jsonObject as? [[String: Any]] {
//                print("📌 JSON 형식: 배열 (Array)")
//                let decodedArray = try JSONDecoder().decode([T].self, from: jsonData)
//                for item in decodedArray {
//                    observer.onNext(item)
//                }
//            } else {
//                throw WebSocketError.decodingFailed(NSError(domain: "InvalidJSONFormat", code: -1, userInfo: [NSLocalizedDescriptionKey: "예상치 못한 JSON 형식입니다."]))
//            }
//        } catch {
//            print("❌ Binary WebSocket 응답 디코딩 실패: \(error.localizedDescription)")
//            observer.onError(WebSocketError.decodingFailed(error))
//        }
//    }
//}
//
//final class KorbitWebSocketManager: BaseWebSocketManager {
//    static let shared = KorbitWebSocketManager()
//    private override init() {}
//}
//
//final class BithumbWebSocketManager: BaseWebSocketManager {
//    static let shared = BithumbWebSocketManager()
//    private override init() {}
//}

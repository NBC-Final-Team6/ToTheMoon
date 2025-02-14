//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/11/25.
//

import Foundation
import Starscream
import RxSwift

class BaseWebSocketManager {
    var socket: WebSocket?
    var disposeBag = DisposeBag()
    var requestString: String?
    
    func connect<T: Decodable, U: Encodable>(to url: URL, decodingType: T.Type, requestPayload: U) -> Observable<T> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(WebSocketError.managerDeinitialized)
                return Disposables.create()
            }
            
            let request = URLRequest(url: url, timeoutInterval: 5)
            self.socket = WebSocket(request: request)
            
            if let jsonData = try? JSONEncoder().encode(requestPayload),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                self.requestString = jsonString
            } else {
                observer.onError(WebSocketError.encodingFailed)
                return Disposables.create()
            }
            
            self.socket?.onEvent = { [weak self] event in
                self?.handleWebSocketEvent(event: event, observer: observer)
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
        })
    }
    
    func handleWebSocketEvent<T: Decodable>(event: WebSocketEvent, observer: AnyObserver<T>) {
        switch event {
        case .connected:
            if let requestString = requestString {
                sendMessage(requestString)
            }
            
        case .text(let text):
            do {
                let data = text.data(using: .utf8) ?? Data()
                let decodedObject = try JSONDecoder().decode(T.self, from: data)
                observer.onNext(decodedObject)
            } catch {
                print("❌ WebSocket 응답 디코딩 실패: \(error.localizedDescription)")
                observer.onError(WebSocketError.decodingFailed(error))
            }
            
        case .error(let error):
            if let error = error {
                print("❌ WebSocket 연결 에러: \(error.localizedDescription)")
                observer.onError(WebSocketError.connectionFailed(error))
            }
            
        case .disconnected(let reason, _):
            observer.onError(WebSocketError.connectionFailed(NSError(
                domain: "WebSocketDisconnected",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: reason]
            )))
        default:
            break
        }
    }
    
    private func decodeWebSocketResponse<T: Decodable>(text: String, observer: AnyObserver<T>) {
        do {
            let data = text.data(using: .utf8) ?? Data()
            let decodedObject = try JSONDecoder().decode(T.self, from: data)
            observer.onNext(decodedObject)
        } catch {
            print("❌ WebSocket 데이터 디코딩 실패: \(error.localizedDescription)")
            observer.onError(WebSocketError.decodingFailed(error))
        }
    }
    
    func disconnect() {
        socket?.disconnect()
        socket = nil
        print("❌ WebSocket 연결 해제 완료")
    }
}

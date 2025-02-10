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
                    if let requestString = self.requestString {
                        self.sendMessage(requestString)
                    }

                case .disconnected(let reason, _):
                    observer.onError(WebSocketError.connectionFailed(NSError(domain: "WebSocketDisconnected", code: -1, userInfo: [NSLocalizedDescriptionKey: reason])))

                case .text(let text):
                    do {
                        let data = text.data(using: .utf8) ?? Data()
                        let decodedObject = try JSONDecoder().decode(T.self, from: data)
                        observer.onNext(decodedObject)
                    } catch {
                        observer.onError(WebSocketError.decodingFailed(error))
                    }

                case .binary(let data):
                    break
                case .error(let error):
                    if let error = error {
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
            }
        }
    }
    
    func sendMessage(_ message: String) {
        socket?.write(string: message, completion: {
        })
    }
}

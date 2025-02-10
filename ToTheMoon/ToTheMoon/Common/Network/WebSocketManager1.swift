//
//  WebSocketManager.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//

import Foundation
import Starscream
import RxSwift

final class WebSocketManager1 {
    static let shared = WebSocketManager1()
    private var socket: WebSocket?
    private var isConnected = false
    private var subscribeQueue: [String] = [] // ✅ 구독 대기열 (WebSocket 연결 후 실행)
    private let subject = PublishSubject<CoinoneWebSocketResponse>()

    private init() {}

    /// **📌 웹소켓 연결 (기존 연결 유지)**
    func connect(to url: URL) -> Observable<CoinoneWebSocketResponse> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(WebSocketError.managerDeinitialized)
                return Disposables.create()
            }

            if self.isConnected {
                print("⚠️ WebSocket 이미 연결됨")
                return self.subject.asObservable() as! Disposable
            }

            var request = URLRequest(url: url, timeoutInterval: 5)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            self.socket = WebSocket(request: request)
            self.socket?.delegate = self
            self.socket?.connect()

            print("✅ WebSocket 연결 시도: \(url)")

            return self.subject.asObservable() as! Disposable
        }
    }

    /// **📌 기존 웹소켓에 새로운 심볼 `SUBSCRIBE` 요청 전송**
    func sendSubscribeMessage(_ symbol: String) {
        let formattedSymbol = symbol.uppercased().replacingOccurrences(of: "KRW-", with: "")

        if isConnected {
            sendSubscription(for: formattedSymbol)
        } else {
            print("⚠️ WebSocket이 아직 연결되지 않음. 대기열에 추가: \(formattedSymbol)")
            subscribeQueue.append(formattedSymbol) // ✅ WebSocket 연결 후 실행하도록 큐에 저장
        }
    }

    /// **🔹 구독 요청을 WebSocket에 전송하는 함수**
    private func sendSubscription(for symbol: String) {
        let requestPayload = CoinoneWebSocketRequest(
            requestType: "SUBSCRIBE",
            channel: "TICKER",
            topic: CoinoneTopic(quoteCurrency: "KRW", targetCurrency: symbol)
        )

        do {
            let jsonData = try JSONEncoder().encode(requestPayload)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                socket?.write(string: jsonString)
                print("📤 WebSocket 메시지 전송 성공: \(jsonString)")
            }
        } catch {
            print("❌ WebSocket 메시지 인코딩 실패: \(error.localizedDescription)")
        }
    }

    /// **📌 WebSocket 연결 해제**
    func disconnect() {
        socket?.disconnect()
        socket = nil
        isConnected = false
        print("❌ WebSocket 연결 해제됨")
    }
}

extension WebSocketManager1: WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected:
            isConnected = true
            print("✅ WebSocket 연결 성공")
            
            // ✅ 연결 후 대기 중이던 구독 요청 실행
            while !subscribeQueue.isEmpty {
                let symbol = subscribeQueue.removeFirst()
                sendSubscription(for: symbol)
            }

        case .disconnected(let reason, _):
            isConnected = false
            print("⚠️ WebSocket 연결 해제됨: \(reason)")

        case .text(let text):
            print("📥 WebSocket 응답 수신: \(text)")
            do {
                let data = text.data(using: .utf8) ?? Data()
                let decodedObject = try JSONDecoder().decode(CoinoneWebSocketResponse.self, from: data)
                subject.onNext(decodedObject)
            } catch {
                print("❌ WebSocket 응답 디코딩 실패: \(error.localizedDescription)")
            }

        case .error(let error):
            if let error = error {
                print("❌ WebSocket 연결 에러: \(error.localizedDescription)")
                subject.onError(error)
            }
        default:
            break
        }
    }
}

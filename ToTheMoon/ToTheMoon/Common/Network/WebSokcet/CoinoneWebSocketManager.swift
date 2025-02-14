//
//  CoinoneWebSocketManager.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/11/25.
//

import Foundation
import Starscream
import RxSwift

final class CoinoneWebSocketManager {
    static let shared = CoinoneWebSocketManager()
    
    private var activeSocket: WebSocket?
    private var backupSocket: WebSocket?
    private var isConnected = false
    private var subscribedSymbols: Set<String> = []
    private let baseURL = Exchange.coinone.webSocketURL
    private let disposeBag = DisposeBag()

    private init() {}

    // **웹소켓 연결 (최대 2개만 유지)**
    func connect<T: Decodable>(symbols: [String]) -> Observable<T> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(WebSocketError.managerDeinitialized)
                return Disposables.create()
            }
            
            let newSymbols = Set(symbols)

            // 기존 구독과 비교하여 변경점 확인
            if newSymbols == self.subscribedSymbols {
                return Disposables.create()
            }

            // 새로운 WebSocket 준비 (backupSocket)
            guard let url = URL(string: self.baseURL) else {
                observer.onError(WebSocketError.invalidURL)
                return Disposables.create()
            }

            let request = URLRequest(url: url)
            let newSocket = WebSocket(request: request)
            self.backupSocket = newSocket

            newSocket.onEvent = { [weak self] event in
                self?.handleWebSocketEvent(event: event, observer: observer, newSymbols: newSymbols)
            }

            newSocket.connect()

            return Disposables.create {
                self.disconnectAll()
            }
        }
    }

    // **WebSocket 이벤트 처리**
    private func handleWebSocketEvent<T: Decodable>(
        event: WebSocketEvent,
        observer: AnyObserver<T>,
        newSymbols: Set<String>
    ) {
        switch event {
        case .connected:
            isConnected = true
            self.switchToBackupWebSocket(newSymbols: newSymbols)

        case .text(let text):
            do {
                let data = text.data(using: .utf8) ?? Data()
                let decodedObject = try JSONDecoder().decode(T.self, from: data)
                observer.onNext(decodedObject)
            } catch {
                print("❌ WebSocket 응답 디코딩 실패: \(error.localizedDescription)")
                observer.onError(WebSocketError.decodingFailed(error))
            }

        case .disconnected(let reason, _):
            isConnected = false
            observer.onError(WebSocketError.connectionFailed(NSError(
                domain: "WebSocketDisconnected",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: reason]
            )))
            reconnect(observer: observer)

        case .error(let error):
            if let error = error {
                print("❌ WebSocket 에러: \(error.localizedDescription)")
                isConnected = false
                observer.onError(WebSocketError.connectionFailed(error))
                reconnect(observer: observer)
            }

        default:
            break
        }
    }

    // **백업 소켓을 활성 소켓으로 변경 (기존 소켓 유지)**
    private func switchToBackupWebSocket(newSymbols: Set<String>) {
        guard let backupSocket = backupSocket else {
            return
        }

        subscribedSymbols = newSymbols
        activeSocket?.disconnect()
        activeSocket = backupSocket
        self.backupSocket = nil

        // 새 WebSocket이 연결된 후 구독 요청 전송
        for symbol in subscribedSymbols {
            sendSubscribeMessage(symbol: symbol)
        }
    }

    // **WebSocket 구독 요청 (새로운 소켓에서도 구독 유지)**
    private func sendSubscribeMessage(symbol: String) {
        guard let socket = activeSocket ?? backupSocket else {
            print("⚠️ WebSocket이 연결되지 않음, 메시지 전송 실패")
            return
        }

        let subscribeMessage: [String: Any] = [
            "request_type": "SUBSCRIBE",
            "channel": "TICKER",
            "topic": [
                "quote_currency": "KRW",
                "target_currency": symbol.uppercased()
            ]
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: subscribeMessage, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                socket.write(string: jsonString)
            }
        } catch {
            print("❌ WebSocket 구독 메시지 JSON 변환 실패: \(error.localizedDescription)")
        }
    }

    // **WebSocket 재연결**
    private func reconnect<T: Decodable>(observer: AnyObserver<T>) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            
            self.connect(symbols: Array(self.subscribedSymbols))
                .subscribe(observer)
                .disposed(by: self.disposeBag)
        }
    }

    // **모든 WebSocket 연결 해제**
    func disconnectAll() {
        activeSocket?.disconnect()
        activeSocket = nil
        backupSocket?.disconnect()
        backupSocket = nil
        isConnected = false
        subscribedSymbols.removeAll()
        print("❌ 모든 WebSocket 연결 해제 완료")
    }
}

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
    
    private var sockets: [Int: WebSocket] = [:] // WebSocket ID별 저장
    private var isConnected: [Int: Bool] = [:] // WebSocket 연결 상태
    private var subscribedSymbols: [Int: Set<String>] = [:] // WebSocket별 구독한 심볼 저장
    private var individualSockets: [String: WebSocket] = [:] // 개별 코인 WebSocket 저장
    private let baseURL = Exchange.coinone.webSocketURL
    private let disposeBag = DisposeBag()
    private let maxSockets = 20 // 최대 WebSocket 개수 유지

    private var remainingSymbols: [String] = [] // 아직 구독되지 않은 심볼 저장

    private init() {}

    // **기존 방식: 20개 WebSocket 유지하며 점진적으로 구독**
    func connect<T: Decodable>(symbols: [String]) -> Observable<T> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(WebSocketError.managerDeinitialized)
                return Disposables.create()
            }

            self.remainingSymbols = Array(symbols.dropFirst(self.maxSockets)) // 남은 심볼 저장

            for (index, symbol) in symbols.prefix(self.maxSockets).enumerated() {
                self.initializeWebSocket(batchID: index, symbol: symbol, observer: observer)
            }

            return Disposables.create {
                self.disconnectAll()
            }
        }
    }

    //**개별 코인 WebSocket 연결**
    func connectSingle<T: Decodable>(symbol: String) -> Observable<T> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(WebSocketError.managerDeinitialized)
                return Disposables.create()
            }

            if let existingSocket = self.individualSockets[symbol] {
                print("⚠️ \(symbol) WebSocket이 이미 연결됨")
                return Disposables.create()
            }

            let request = URLRequest(url: URL(string: self.baseURL)!)
            let newSocket = WebSocket(request: request)
            self.individualSockets[symbol] = newSocket

            newSocket.onEvent = { [weak self] event in
                self?.handleWebSocketEvent(event: event, symbol: symbol, observer: observer)
            }

            newSocket.connect()

            return Disposables.create {
                self.disconnectSingle(symbol: symbol)
            }
        }
    }

    private func initializeWebSocket<T: Decodable>(
        batchID: Int,
        symbol: String,
        observer: AnyObserver<T>
    ) {
        if sockets[batchID] != nil {
            return
        }

        let request = URLRequest(url: URL(string: self.baseURL)!)
        let newSocket = WebSocket(request: request)
        sockets[batchID] = newSocket
        isConnected[batchID] = false
        subscribedSymbols[batchID] = [symbol]

        newSocket.onEvent = { [weak self] event in
            self?.handleWebSocketEvent(event: event, batchID: batchID, observer: observer)
        }

        newSocket.connect()
    }

    private func handleWebSocketEvent<T: Decodable>(
        event: WebSocketEvent,
        batchID: Int? = nil,
        symbol: String? = nil,
        observer: AnyObserver<T>
    ) {
        switch event {
        case .connected:
            if let batchID = batchID {
                isConnected[batchID] = true
                if let firstSymbol = subscribedSymbols[batchID]?.first {
                    sendSubscribeMessage(batchID: batchID, symbol: firstSymbol)
                }
            } else if let symbol = symbol {
                sendSubscribeMessage(symbol: symbol)
            }

        case .text(let text):
            do {
                let data = text.data(using: .utf8) ?? Data()
                let decodedObject = try JSONDecoder().decode(T.self, from: data)
                observer.onNext(decodedObject)

                if let batchID = batchID {
                    addNextSubscription(batchID: batchID)
                }

            } catch {
                print("❌ WebSocket 응답 디코딩 실패: \(error.localizedDescription)")
                observer.onError(WebSocketError.decodingFailed(error))
            }

        case .disconnected(let reason, _):
            observer.onError(WebSocketError.connectionFailed(NSError(domain: "WebSocketDisconnected", code: -1, userInfo: [NSLocalizedDescriptionKey: reason])))

        case .error(let error):
            if let error = error {
                print("❌ WebSocket 에러: \(error.localizedDescription)")
                observer.onError(WebSocketError.connectionFailed(error))
            }

        default:
            break
        }
    }

    private func addNextSubscription(batchID: Int) {
        guard let socket = sockets[batchID], isConnected[batchID] == true else {
            return
        }

        if !remainingSymbols.isEmpty {
            let nextSymbol = remainingSymbols.removeFirst()
            subscribedSymbols[batchID]?.insert(nextSymbol)
            sendSubscribeMessage(batchID: batchID, symbol: nextSymbol)
        }
    }

    func disconnectSingle(symbol: String) {
        individualSockets[symbol]?.disconnect()
        individualSockets.removeValue(forKey: symbol)
        print("❌ \(symbol) WebSocket 연결 해제")
    }

    func disconnect(batchID: Int) {
        sockets[batchID]?.disconnect()
        sockets.removeValue(forKey: batchID)
        isConnected[batchID] = false
        subscribedSymbols.removeValue(forKey: batchID)
        print("❌ \(batchID) WebSocket 연결 해제")
    }

    func disconnectAll() {
        sockets.values.forEach { $0.disconnect() }
        sockets.removeAll()
        isConnected.removeAll()
        subscribedSymbols.removeAll()
        remainingSymbols.removeAll()

        individualSockets.values.forEach { $0.disconnect() }
        individualSockets.removeAll()

        print("❌ 모든 WebSocket 연결 해제 완료")
    }

    func sendSubscribeMessage(batchID: Int? = nil, symbol: String) {
        guard let socket = batchID != nil ? sockets[batchID!] : individualSockets[symbol] else {
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
                print("📤 WebSocket 구독 성공: \(jsonString)")
            }
        } catch {
            print("❌ WebSocket 구독 메시지 JSON 변환 실패: \(error.localizedDescription)")
        }
    }
}


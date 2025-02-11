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
    private var sockets: [Int: WebSocket] = [:]
    private var isConnected: [Int: Bool] = [:]
    private var subscribedSymbols: [Int: Set<String>] = [:]
    private let baseURL = "wss://stream.coinone.co.kr"
    private let disposeBag = DisposeBag()
    private let maxSockets = 20
    
    private var remainingSymbols: [String] = []
    
    private init() {}
    
    func connect<T: Decodable>(symbols: [String]) -> Observable<T> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(WebSocketError.managerDeinitialized)
                return Disposables.create()
            }
            
            self.remainingSymbols = Array(symbols.dropFirst(self.maxSockets))
            
            for (index, symbol) in symbols.prefix(self.maxSockets).enumerated() {
                self.initializeWebSocket(batchID: index, symbol: symbol, observer: observer)
            }
            
            return Disposables.create {
                self.disconnectAll()
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
        batchID: Int,
        observer: AnyObserver<T>
    ) {
        switch event {
        case .connected:
            isConnected[batchID] = true
            if let firstSymbol = subscribedSymbols[batchID]?.first {
                sendSubscribeMessage(batchID: batchID, symbol: firstSymbol)
            }
            
        case .text(let text):
            do {
                let data = text.data(using: .utf8) ?? Data()
                let decodedObject = try JSONDecoder().decode(T.self, from: data)
                observer.onNext(decodedObject)
                
                addNextSubscription(batchID: batchID)
                
            } catch {
                print("❌ \(batchID) WebSocket 응답 디코딩 실패: \(error.localizedDescription)")
                observer.onError(WebSocketError.decodingFailed(error))
            }
            
        case .disconnected(let reason, _):
            isConnected[batchID] = false
            observer.onError(WebSocketError.connectionFailed(NSError(domain: "WebSocketDisconnected", code: -1, userInfo: [NSLocalizedDescriptionKey: reason])))
            
        case .error(let error):
            if let error = error {
                print("❌ \(batchID) WebSocket 에러: \(error.localizedDescription)")
                isConnected[batchID] = false
                observer.onError(WebSocketError.connectionFailed(error))
            }
            
        default:
            break
        }
    }
    
    private func addNextSubscription(batchID: Int) {
        guard let socket = sockets[batchID], isConnected[batchID] == true else {
            print("⚠️ \(batchID) WebSocket이 연결되지 않음, 추가 구독 실패")
            return
        }
        
        if !remainingSymbols.isEmpty {
            let nextSymbol = remainingSymbols.removeFirst()
            subscribedSymbols[batchID]?.insert(nextSymbol)
            sendSubscribeMessage(batchID: batchID, symbol: nextSymbol)
        }
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
        print("❌ 모든 WebSocket 연결 해제 완료")
    }
    
    func sendSubscribeMessage(batchID: Int, symbol: String) {
        guard let socket = sockets[batchID] else {
            print("⚠️ \(batchID) WebSocket이 연결되지 않음, 메시지 전송 실패")
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
                print("📤 \(batchID) WebSocket 추가 구독 성공: \(jsonString)")
            }
        } catch {
            print("❌ \(batchID) WebSocket 구독 메시지 JSON 변환 실패: \(error.localizedDescription)")
        }
    }
}


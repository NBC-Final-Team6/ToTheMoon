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
    private var sockets: [Int: WebSocket] = [:]  // ✅ 20개 단위로 WebSocket 관리
    private var isConnected: [Int: Bool] = [:]   // ✅ WebSocket별 연결 상태 저장
    private var subscribedSymbols: [Int: Set<String>] = [:] // ✅ 각 WebSocket이 구독한 심볼 목록
    private let baseURL = "wss://stream.coinone.co.kr"  // ✅ WebSocket 서버 주소
    private let disposeBag = DisposeBag()
    private let maxSockets = 20 // ✅ 유지할 WebSocket 개수
    
    private var remainingSymbols: [String] = [] // ✅ 전역 변수로 변경하여 관리
    
    private init() {}
    
    /// ✅ 초기 20개 WebSocket 연결, 각 WebSocket은 처음엔 1개 심볼만 구독
    func connect<T: Decodable>(symbols: [String]) -> Observable<T> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(WebSocketError.managerDeinitialized)
                return Disposables.create()
            }
            
            self.remainingSymbols = Array(symbols.dropFirst(self.maxSockets)) // ✅ 추가적으로 구독할 심볼 저장
            
            for (index, symbol) in symbols.prefix(self.maxSockets).enumerated() {
                self.initializeWebSocket(batchID: index, symbol: symbol, observer: observer)
            }
            
            return Disposables.create {
                self.disconnectAll()
            }
        }
    }
    
    /// ✅ 개별 WebSocket을 생성하고 처음엔 1개의 심볼을 구독
    private func initializeWebSocket<T: Decodable>(
        batchID: Int,
        symbol: String,
        observer: AnyObserver<T>
    ) {
        // ✅ 이미 연결된 경우 무시
        if sockets[batchID] != nil {
            print("✅ \(batchID) WebSocket 이미 연결됨")
            return
        }
        
        print("🔗 \(batchID) WebSocket 새 연결 시작 (초기 구독: \(symbol))")
        let request = URLRequest(url: URL(string: self.baseURL)!)
        
        let newSocket = WebSocket(request: request)
        sockets[batchID] = newSocket
        isConnected[batchID] = false
        subscribedSymbols[batchID] = [symbol] // ✅ 초기 구독 심볼 저장
        
        // ✅ WebSocket별 구독 심볼 로깅
        print("📝 WebSocket \(batchID) 초기 구독 심볼: \(subscribedSymbols[batchID] ?? [])")
        
        newSocket.onEvent = { [weak self] event in
            self?.handleWebSocketEvent(event: event, batchID: batchID, observer: observer)
        }
        
        newSocket.connect()
    }
    
    /// ✅ WebSocket 이벤트 핸들링
    private func handleWebSocketEvent<T: Decodable>(
        event: WebSocketEvent,
        batchID: Int,
        observer: AnyObserver<T>
    ) {
        switch event {
        case .connected:
            print("✅ \(batchID) WebSocket 연결 성공")
            isConnected[batchID] = true
            if let firstSymbol = subscribedSymbols[batchID]?.first {
                sendSubscribeMessage(batchID: batchID, symbol: firstSymbol)
            }
            
        case .text(let text):
            print("📥 \(batchID) WebSocket 응답: \(text)")
            do {
                let data = text.data(using: .utf8) ?? Data()
                let decodedObject = try JSONDecoder().decode(T.self, from: data)
                observer.onNext(decodedObject)
                
                // ✅ 정상적으로 응답을 받으면 다음 심볼을 구독
                addNextSubscription(batchID: batchID)
                
            } catch {
                print("❌ \(batchID) WebSocket 응답 디코딩 실패: \(error.localizedDescription)")
                observer.onError(WebSocketError.decodingFailed(error))
            }
            
        case .disconnected(let reason, _):
            print("⚠️ \(batchID) WebSocket 연결 해제됨: \(reason)")
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
    
    /// ✅ 응답이 정상적으로 오면 추가 구독 메시지 전송
    private func addNextSubscription(batchID: Int) {
        guard let socket = sockets[batchID], isConnected[batchID] == true else {
            print("⚠️ \(batchID) WebSocket이 연결되지 않음, 추가 구독 실패")
            return
        }
        
        // ✅ 남은 심볼이 있으면 순차적으로 하나씩 가져옴
        if !remainingSymbols.isEmpty {
            let nextSymbol = remainingSymbols.removeFirst() // ✅ 올바르게 다음 심볼을 가져옴
            subscribedSymbols[batchID]?.insert(nextSymbol)
            // ✅ 추가 구독 로깅
                    print("📤 WebSocket \(batchID) 추가 구독 요청: \(nextSymbol)")

            sendSubscribeMessage(batchID: batchID, symbol: nextSymbol)
        }
    }
    
    /// ✅ 특정 WebSocket 연결 해제
    func disconnect(batchID: Int) {
        sockets[batchID]?.disconnect()
        sockets.removeValue(forKey: batchID)
        isConnected[batchID] = false
        subscribedSymbols.removeValue(forKey: batchID)
        print("❌ \(batchID) WebSocket 연결 해제")
    }
    
    /// ✅ 모든 WebSocket 연결 해제
    func disconnectAll() {
        sockets.values.forEach { $0.disconnect() }
        sockets.removeAll()
        isConnected.removeAll()
        subscribedSymbols.removeAll()
        remainingSymbols.removeAll()
        print("❌ 모든 WebSocket 연결 해제 완료")
    }
    
    /// ✅ 특정 심볼의 WebSocket에 `SUBSCRIBE` 메시지 전송
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


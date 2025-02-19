//
//  UpbitWebSocketManager.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/8/25.
//

import Foundation
import Starscream
import RxSwift

final class UpbitWebSocketManager: BaseWebSocketManager {
    static let shared = UpbitWebSocketManager()
    private let baseURL = Exchange.upbit.webSocketURL
    
    private var activeSocket: WebSocket?
    private var backupSocket: WebSocket?
    private var subscribedSymbols: Set<String> = []
    
    private override init() {}
    
    // **Upbit WebSocket 연결 (최대 2개 유지)**
    func connect<T: Decodable>(symbols: [String], decodingType: T.Type) -> Observable<T> {
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
            
            guard let url = URL(string: self.baseURL) else {
                observer.onError(WebSocketError.invalidURL)
                return Disposables.create()
            }
            
            _ = self.createRequestPayload(symbols: symbols)
            let request = URLRequest(url: url)
            let newSocket = WebSocket(request: request)
            self.backupSocket = newSocket
            
            newSocket.onEvent = { [weak self] event in
                self?.handleWebSocketEvent(event: event, observer: observer, decodingType: decodingType, newSymbols: newSymbols)
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
        decodingType: T.Type,
        newSymbols: Set<String>
    ) {
        switch event {
        case .connected:
            self.switchToBackupWebSocket(newSymbols: newSymbols)
            
        case .binary(let data):
            decodeBinaryResponse(data, decodingType: decodingType, observer: observer)
            
        case .disconnected(let reason, _):
            observer.onError(WebSocketError.connectionFailed(NSError(
                domain: "WebSocketDisconnected",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: reason]
            )))
            reconnect(observer: observer)
            
        case .error(let error):
            if let error = error {
                print("❌ WebSocket 에러: \(error.localizedDescription)")
                observer.onError(WebSocketError.connectionFailed(error))
                reconnect(observer: observer)
            }
            
        default:
            break
        }
    }
    
    // **백업 소켓을 활성 소켓으로 변경**
    private func switchToBackupWebSocket(newSymbols: Set<String>) {
        guard let backupSocket = backupSocket else {
            return
        }
        
        subscribedSymbols = newSymbols
        activeSocket?.disconnect()
        activeSocket = backupSocket
        self.backupSocket = nil
        
        // 새 WebSocket이 연결된 후 기존 구독도 유지하면서 새로운 구독 추가
        sendSubscribeMessage(symbols: subscribedSymbols)
    }
    
    // **WebSocket 구독 요청**
    private func sendSubscribeMessage(symbols: Set<String>) {
        guard let socket = activeSocket ?? backupSocket else {
            print("⚠️ WebSocket이 연결되지 않음, 메시지 전송 실패")
            return
        }
        
        let subscribeMessage = createRequestPayload(symbols: Array(symbols))
        
        do {
            let jsonData = try JSONEncoder().encode(subscribeMessage)
            socket.write(data: jsonData)
        } catch {
            print("❌ WebSocket 구독 메시지 JSON 변환 실패: \(error.localizedDescription)")
        }
    }
    
    // **구독 요청 JSON 생성**
    private func createRequestPayload(symbols: [String]) -> [AnyEncodable] {
        let formattedSymbols = symbols.map { "KRW-\($0.uppercased())" }
        return [
            AnyEncodable(["ticket": AnyEncodable("UNIQUE_TICKET_ID")]),
            AnyEncodable([
                "type": AnyEncodable("ticker"),
                "codes": AnyEncodable(formattedSymbols.map { AnyEncodable($0) }),
                "isOnlyRealtime": AnyEncodable(true)
            ])
        ]
    }
    
    // **Binary 데이터 디코딩**
    private func decodeBinaryResponse<T: Decodable>(_ data: Data, decodingType: T.Type, observer: AnyObserver<T>) {
        do {
            let decodedObject = try JSONDecoder().decode(T.self, from: data)
            observer.onNext(decodedObject)
        } catch {
            print("❌ Binary WebSocket 응답 디코딩 실패: \(error.localizedDescription)")
            observer.onError(WebSocketError.decodingFailed(error))
        }
    }
    
    // **WebSocket 재연결**
    private func reconnect<T: Decodable>(observer: AnyObserver<T>) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            
            self.connect(symbols: Array(self.subscribedSymbols), decodingType: T.self)
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
        subscribedSymbols.removeAll()
    }
}

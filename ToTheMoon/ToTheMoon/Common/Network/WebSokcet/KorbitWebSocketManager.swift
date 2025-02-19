//
//  KorbitWebSocketManager.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/11/25.
//

import Foundation
import Starscream
import RxSwift

final class KorbitWebSocketManager: BaseWebSocketManager {
    static let shared = KorbitWebSocketManager()
    private let baseURL = Exchange.korbit.webSocketURL

     private var activeSocket: WebSocket?
     private var backupSocket: WebSocket?
     private var subscribedSymbols: Set<String> = []

     private override init() {}

     // **최대 2개의 WebSocket을 유지하면서 새로운 구독을 추가**
     func connect<T: Decodable>(symbols: [String], decodingType: T.Type) -> Observable<T> {
         return Observable.create { [weak self] observer in
             guard let self = self else {
                 observer.onError(WebSocketError.managerDeinitialized)
                 return Disposables.create()
             }

             let newSymbols = Set(symbols)

             if newSymbols == self.subscribedSymbols {
                 return Disposables.create()
             }

             guard let url = URL(string: self.baseURL) else {
                 observer.onError(WebSocketError.invalidURL)
                 return Disposables.create()
             }

             _ = self.createRequestPayload(symbols: symbols)

             if self.activeSocket == nil {
                 return self.establishNewWebSocket(url: url, symbols: newSymbols, decodingType: decodingType, observer: observer)
             } else if self.backupSocket == nil {
                 return self.establishBackupWebSocket(url: url, symbols: newSymbols, decodingType: decodingType, observer: observer)
             } else {
                 return self.switchToBackupWebSocket(newSymbols: newSymbols, decodingType: decodingType, observer: observer)
             }
         }
     }

     // **새로운 WebSocket을 설정 (최초 연결)**
     private func establishNewWebSocket<T: Decodable>(
         url: URL,
         symbols: Set<String>,
         decodingType: T.Type,
         observer: AnyObserver<T>
     ) -> Disposable {
         let requestPayload = self.createRequestPayload(symbols: Array(symbols))
         return super.connect(to: url, decodingType: decodingType, requestPayload: requestPayload)
             .do(onNext: { _ in
                 self.subscribedSymbols = symbols
             })
             .retry(3)
             .subscribe(observer)
     }

     // **백업 WebSocket을 설정**
     private func establishBackupWebSocket<T: Decodable>(
         url: URL,
         symbols: Set<String>,
         decodingType: T.Type,
         observer: AnyObserver<T>
     ) -> Disposable {
         let requestPayload = self.createRequestPayload(symbols: Array(symbols))
         self.backupSocket = WebSocket(request: URLRequest(url: url))

         return super.connect(to: url, decodingType: decodingType, requestPayload: requestPayload)
             .do(onNext: { _ in
                 self.subscribedSymbols = symbols
                 self.activeSocket?.disconnect() // 기존 활성 소켓 종료
                 self.activeSocket = self.backupSocket // 백업 소켓을 활성 소켓으로 변경
                 self.backupSocket = nil
             })
             .retry(3)
             .subscribe(observer)
     }

     // **기존 소켓을 해제하고 새로운 소켓으로 교체**
     private func switchToBackupWebSocket<T: Decodable>(
         newSymbols: Set<String>,
         decodingType: T.Type,
         observer: AnyObserver<T>
     ) -> Disposable {
         guard let url = URL(string: self.baseURL) else {
             observer.onError(WebSocketError.invalidURL)
             return Disposables.create()
         }

         // 기존 WebSocket을 해제
         self.activeSocket?.disconnect()
         self.activeSocket = nil

         // 백업 소켓을 활성화 후 새로운 WebSocket을 설정
         return self.establishBackupWebSocket(url: url, symbols: newSymbols, decodingType: decodingType, observer: observer)
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
     private func createRequestPayload(symbols: [String]) -> [KorbitWebSocketRequest] {
         return [KorbitWebSocketRequest(
             method: "subscribe",
             type: "ticker",
             symbols: symbols
         )]
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
         super.disconnect()
         activeSocket?.disconnect()
         activeSocket = nil
         backupSocket?.disconnect()
         backupSocket = nil
         subscribedSymbols.removeAll()
         print("❌ 코빗 모든 WebSocket 연결 해제 완료")
     }
 }

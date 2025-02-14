//
//  BithumbWebSocketManager.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/11/25.
//

import Foundation
import Starscream
import RxSwift

final class BithumbWebSocketManager: BaseWebSocketManager {
    static let shared = BithumbWebSocketManager()
    private let baseURL = Exchange.bithumb.webSocketURL

    private var activeSocket: WebSocket?
    private var backupSocket: WebSocket?
    private var subscribedSymbols: Set<String> = []

    private override init() {}

    // **WebSocket 연결 (최대 2개 유지)**
    func connect<T: Decodable>(symbols: [String], decodingType: T.Type) -> Observable<T> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(WebSocketError.managerDeinitialized)
                return Disposables.create()
            }

            let formattedSymbols = symbols.map { self.formatSymbol($0) }
            let newSymbols = Set(formattedSymbols)

            if newSymbols == self.subscribedSymbols {
                return Disposables.create()
            }

            guard let url = URL(string: self.baseURL) else {
                observer.onError(WebSocketError.invalidURL)
                return Disposables.create()
            }

            _ = self.createRequestPayload(symbols: formattedSymbols)

            if self.activeSocket == nil {
                return self.establishNewWebSocket(url: url, symbols: newSymbols, decodingType: decodingType, observer: observer)
            } else if self.backupSocket == nil {
                return self.establishBackupWebSocket(url: url, symbols: newSymbols, decodingType: decodingType, observer: observer)
            } else {
                return self.switchToBackupWebSocket(newSymbols: newSymbols, decodingType: decodingType, observer: observer)
            }
        }
    }

    // **Bithumb 심볼 변환 (BTC → BTC_KRW)**
    private func formatSymbol(_ symbol: String) -> String {
        return "\(symbol.uppercased())_KRW"
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
            .retry(3) // 연결 실패 시 3번 재시도
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

    // **WebSocket 이벤트 처리**
    private func handleWebSocketEvent<T: Decodable>(
        event: WebSocketEvent,
        observer: AnyObserver<T>,
        decodingType: T.Type,
        newSymbols: Set<String>
    ) {
        switch event {
        case .connected:
            self.switchToBackupWebSocket(newSymbols: newSymbols, decodingType: decodingType, observer: observer)

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

    // **Binary 데이터 디코딩**
    private func decodeBinaryResponse<T: Decodable>(
        _ data: Data,
        decodingType: T.Type,
        observer: AnyObserver<T>
    ) {
        do {
            let decodedObject = try JSONDecoder().decode(T.self, from: data)
            observer.onNext(decodedObject)
        } catch {
            print("❌ Binary WebSocket 응답 디코딩 실패: \(error.localizedDescription)")
            observer.onError(WebSocketError.decodingFailed(error))
        }
    }

    // **WebSocket 구독 요청 JSON 생성**
    private func createRequestPayload(symbols: [String]) -> BithumbWebSocketTickerRequest {
        return BithumbWebSocketTickerRequest(
            type: "ticker",
            symbols: symbols,
            tickTypes: ["24H"]
        )
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
        print("❌ 모든 WebSocket 연결 해제 완료")
    }
}

//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//

import Foundation
import RxSwift

final class CoinoneWebSocketService {
    private let baseURL = "wss://stream.coinone.co.kr"
    
    /// **KRW 마켓 특정 티커 데이터 수신**
    func fetchTickerData(quoteCurrency: String, targetCurrency: String) -> Observable<CoinoneWebSocketResponse> {
        let requestPayload = CoinoneWebSocketRequest(
            requestType: "SUBSCRIBE",
            channel: "TICKER",
            topic: CoinoneTopic(quoteCurrency: quoteCurrency, targetCurrency: targetCurrency)
        )
        
        return WebSocketManager.shared.connect(
            to: URL(string: baseURL)!,
            decodingType: CoinoneWebSocketResponse.self,
            requestPayload: requestPayload
        ).do(onNext: { [weak self] response in
            self?.handleResponse(response)
        }, onError: { error in
            print("❌ WebSocket 에러 발생: \(error.localizedDescription)")
        })
    }
    
    /// **📌 응답 처리**
    private func handleResponse(_ response: CoinoneWebSocketResponse) {
        switch response {
        case .connected(let connectedData):
            print("✅ 연결 성공: Session ID - \(connectedData.sessionId)")
        case .subscribed(let subscribedData):
            print("✅ 구독 성공: \(subscribedData.data.quoteCurrency)/\(subscribedData.data.targetCurrency)")
        case .data(let tickerDataResponse):
            displayTickerData(tickerDataResponse.data)
        }
    }
    
    /// **📌 티커 데이터 출력**
    private func displayTickerData(_ tickerData: TickerData) {
        print("""
        ✅ 코인원 실시간 시세 업데이트:
         - 심볼: \(tickerData.quoteCurrency)/\(tickerData.targetCurrency)
         - 현재가: \(tickerData.last)
         - 고가: \(tickerData.high), 저가: \(tickerData.low)
         - 24시간 거래량: \(tickerData.quoteVolume)
        """)
    }
}

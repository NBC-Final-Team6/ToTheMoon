//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/25/25.
//

enum Exchange: String {
    case bithumb = "Bithumb"
    case coinone = "CoinOne"
    case korbit = "Korbit"
    case upbit = "Upbit"
    
    // 거래소의 기본 URL을 반환
    var baseURL: String {
        switch self {
        case .bithumb:
            return "https://api.bithumb.com"
        case .coinone:
            return "https://api.coinone.co.kr"
        case .korbit:
            return "https://api.korbit.co.kr"
        case .upbit:
            return "https://api.upbit.com"
        }
    }
    
    // 거래소의 WebSocket URL
        var webSocketURL: String {
            switch self {
            case .bithumb:
                return "wss://pubwss.bithumb.com/pub/ws"
            case .coinone:
                return "wss://stream.coinone.co.kr"
            case .korbit:
                return "wss://ws-api.korbit.co.kr/v2/ws"
            case .upbit:
                return "wss://api.upbit.com/websocket/v1"
            }
        }
}

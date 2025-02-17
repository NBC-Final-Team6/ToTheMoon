//
//  WebSocketError.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/11/25.
//

import Foundation

enum WebSocketError: Error {
    case invalidURL
    case invalidSymbols
    case managerDeinitialized
    case encodingFailed
    case decodingFailed(Error)
    case connectionFailed(Error)
    case disconnected(reason: String, code: Int)
    case unknown
}

extension WebSocketError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "유효하지 않은 WebSocket URL입니다."
        case .invalidSymbols:
            return "심볼 목록이 비어 있습니다."
        case .managerDeinitialized:
            return "WebSocketManager가 예상치 못하게 해제되었습니다."
        case .encodingFailed:
            return "WebSocket 요청을 JSON으로 변환하는 데 실패했습니다."
        case .decodingFailed(let error):
            return "WebSocket 응답을 디코딩하는 데 실패했습니다: \(error.localizedDescription)"
        case .connectionFailed(let error):
            return "WebSocket 연결이 실패했습니다: \(error.localizedDescription)"
        case .disconnected(let reason, _):
            return "WebSocket 연결이 해제되었습니다: \(reason)"
        case .unknown:
            return "알 수 없는 WebSocket 오류가 발생했습니다."
        }
    }
}

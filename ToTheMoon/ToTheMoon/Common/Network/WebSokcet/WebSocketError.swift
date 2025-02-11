//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//

import Foundation

/// **WebSocket 관련 에러 타입 정의**
enum WebSocketError: Error, LocalizedError {
    case decodingFailed(Error)      // JSON 디코딩 실패
    case encodingFailed             // JSON 인코딩 실패
    case connectionFailed(Error)    // 연결 실패
    case managerDeinitialized       // WebSocketManager 해제됨
    case invalidResponse            // 유효하지 않은 응답
    case unknownError               // 알 수 없는 에러 발생

    var errorDescription: String? {
        switch self {
        case .decodingFailed(let error):
            return "❌ WebSocket 응답 디코딩 실패: \(error.localizedDescription)"
        case .encodingFailed:
            return "❌ WebSocket 요청 인코딩 실패!"
        case .connectionFailed(let error):
            return "⚠️ WebSocket 연결 실패: \(error.localizedDescription)"
        case .managerDeinitialized:
            return "⚠️ WebSocketManager가 해제되었습니다!"
        case .invalidResponse:
            return "❌ WebSocket에서 유효하지 않은 응답을 받았습니다!"
        case .unknownError:
            return "⚠️ 알 수 없는 WebSocket 오류 발생!"
        }
    }
}

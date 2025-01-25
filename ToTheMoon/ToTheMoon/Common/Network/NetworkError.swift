//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidUrl
    case dataFetchFail
    case decodingFail
    case unknownError
    case invalidData
    
    // LocalizedError의 errorDescription 제공
    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return "잘못된 URL!"
        case .dataFetchFail:
            return "데이터 로드 실패!"
        case .decodingFail:
            return "디코딩 실패!"
        case .unknownError:
            return "알 수 없는 에러 발생!"
        case .invalidData:
            return "데이터가 없습니다!"
        }
    }
}

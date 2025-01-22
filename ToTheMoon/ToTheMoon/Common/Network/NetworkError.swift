//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

enum NetworkError: Error {
    case invalidUrl
    case dataFetchFail
    case decodingFail
    
    var description: String {
        switch self {
        case .invalidUrl:
            return "잘못된 URL"
        case .dataFetchFail:
            return "데이터 로드 실패"
        case .decodingFail:
            return "디코딩 실패"
        }
    }
}

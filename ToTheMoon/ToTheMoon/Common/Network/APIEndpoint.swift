//
//  APIEndpoint.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

enum APIEndpoint {
    case coinGecko

    var baseURL: String {
        switch self {
        case .coinGecko:
            return "https://api.coingecko.com/api/v3/coins"
        }
    }
}

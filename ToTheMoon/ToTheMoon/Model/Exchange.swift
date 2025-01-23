//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/23/25.
//

enum Exchange: String {
    case bithumb
    case upbit
    case coinone
    case korbit
    case gopax
    case CoinGecko
    
    var baseURL: String {
        switch self {
        case .bithumb:
            return "https://api.bithumb.com"
        case .upbit:
            return "https://api.upbit.com"
        case .coinone:
            return "https://api.korbit.co.kr"
        case .gopax:
            return "https://api.gopax.co.kr"
        case .CoinGecko:
            return "https://api.coingecko.com/api/v3/coins"
        }
    }
}

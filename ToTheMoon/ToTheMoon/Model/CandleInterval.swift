//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/24/25.
//

enum CandleInterval {
    case minute     
    case day
    case week
    case month

    /// 업비트와 빗썸에서 사용하는 rawValue
    var upbitAndBithumbRawValue: String {
        switch self {
        case .minute:
            return "minutes/1" // 1분 단위는 "/1"로 고정
        case .day:
            return "days" // day → days
        case .week:
            return "weeks" // week → weeks
        case .month:
            return "months" // month → months
        }
    }
    
    /// 코인원에서 사용하는 rawValue
    var coinOneRawValue: String {
        switch self {
        case .minute:
            return "1m"
        case .day:
            return "1d"
        case .week:
            return "1w"
        case .month:
            return "1mon"
        }
    }

    /// 코빗에서 사용하는 rawValue
    var korbitRawValue: String {
        switch self {
        case .minute:
            return "1" // 항상 1분 단위로 고정
        case .day:
            return "1D" // 1일
        case .week:
            return "1W" // 1주
        case .month:
            return "1M" // 1개월
        }
    }
    
    
}

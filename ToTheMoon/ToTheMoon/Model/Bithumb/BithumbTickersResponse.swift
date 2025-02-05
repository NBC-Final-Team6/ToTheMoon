//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/31/25.
//

import Foundation

// MARK: - Bithumb API 응답 모델
struct BithumbTickersResponse: Decodable {
    let data: CoinDataWrapper
    
    struct CoinDataWrapper: Codable {
        let date: String
        let coins: [String: CoinData]
        
        enum CodingKeys: String, CodingKey {
            case date
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.date = try container.decode(String.self, forKey: .date)
            
            let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKeys.self)
            var tempCoins = [String: CoinData]()
            
            for key in dynamicContainer.allKeys {
                if key.stringValue != "date" {
                    let coinData = try dynamicContainer.decode(CoinData.self, forKey: key)
                    tempCoins[key.stringValue] = coinData
                }
            }
            self.coins = tempCoins
        }
    }
}

// MARK: - 코인 데이터 모델
struct CoinData: Decodable {
    let openingPrice: Double
    let closingPrice: Double
    let minPrice: Double
    let maxPrice: Double
    let unitsTraded: Double
    let accTradeValue: Double
    let prevClosingPrice: Double
    let unitsTraded24H: Double
    let accTradeValue24H: Double
    let fluctate24H: Double
    let fluctateRate24H: Double
    
    enum CodingKeys: String, CodingKey {
        case openingPrice = "opening_price"
        case closingPrice = "closing_price"
        case minPrice = "min_price"
        case maxPrice = "max_price"
        case unitsTraded = "units_traded"
        case accTradeValue = "acc_trade_value"
        case prevClosingPrice = "prev_closing_price"
        case unitsTraded24H = "units_traded_24H"
        case accTradeValue24H = "acc_trade_value_24H"
        case fluctate24H = "fluctate_24H"
        case fluctateRate24H = "fluctate_rate_24H"
    }
    
    // API에서 모든 값을 문자열(String)로 제공하므로 Double 변환을 시도
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.openingPrice = Double(try container.decode(String.self, forKey: .openingPrice)) ?? 0.0
        self.closingPrice = Double(try container.decode(String.self, forKey: .closingPrice)) ?? 0.0
        self.minPrice = Double(try container.decode(String.self, forKey: .minPrice)) ?? 0.0
        self.maxPrice = Double(try container.decode(String.self, forKey: .maxPrice)) ?? 0.0
        self.unitsTraded = Double(try container.decode(String.self, forKey: .unitsTraded)) ?? 0.0
        self.accTradeValue = Double(try container.decode(String.self, forKey: .accTradeValue)) ?? 0.0
        self.prevClosingPrice = Double(try container.decode(String.self, forKey: .prevClosingPrice)) ?? 0.0
        self.unitsTraded24H = Double(try container.decode(String.self, forKey: .unitsTraded24H)) ?? 0.0
        self.accTradeValue24H = Double(try container.decode(String.self, forKey: .accTradeValue24H)) ?? 0.0
        self.fluctate24H = Double(try container.decode(String.self, forKey: .fluctate24H)) ?? 0.0
        self.fluctateRate24H = Double(try container.decode(String.self, forKey: .fluctateRate24H)) ?? 0.0
    }
}

// MARK: - 동적 코딩 키 처리
struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    init?(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { return nil }
    init?(intValue: Int) { return nil }
}

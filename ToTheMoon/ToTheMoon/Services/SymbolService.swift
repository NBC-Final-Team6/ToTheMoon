//
//  FetchCoinData.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

import Foundation
import RxSwift
import UIKit

final class CoinService {
    private let networkManager = NetworkManager.shared
    private let baseURL = ExchangeEndpoint.CoinGecko.baseURL
    
    
    func fetchCoinData(coinSymbol: String) -> Single<Symbol> {
        let endpoint = "\(baseURL)/\(coinSymbol)"
        guard let url = URL(string: endpoint) else {
            return Single.error(NetworkError.invalidUrl)
        }
        return networkManager.fetch(url: url)
    }
    
    func fetchCoinThumbImageURL(coinSymbol: String) -> Single<String> {
        return fetchCoinData(coinSymbol: coinSymbol)
            .map { coin in
                guard let thumbUrl = coin.image?.thumb, !thumbUrl.isEmpty else {
                    throw NetworkError.invalidData
                }
                return thumbUrl
            }
    }
}

//
//  FetchCoinData.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

import RxSwift
import Foundation

final class CoinService {
    private let networkManager = NetworkManager.shared
    private let baseURL = ExchangeEndpoint.CoinGecko.baseURL
    
    
    func fetchCoinData(coinID: String) -> Single<Coin> {
        let endpoint = "\(baseURL)/\(coinID)"
        guard let url = URL(string: endpoint) else {
            return Single.error(NetworkError.invalidUrl)
        }
        return NetworkManager.shared.fetch(url: url)
    }
}

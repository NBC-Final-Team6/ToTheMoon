//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//

import Foundation
import RxSwift

class BaseService {
    private let networkManager = NetworkManager.shared
    let baseURL: String

    init(baseURL: String) {
        self.baseURL = baseURL
    }

    func request<T: Decodable>(endpoint: String, queryParams: [String: String]? = nil) -> Single<T> {
        var urlComponents = URLComponents(string: baseURL + endpoint)
        urlComponents?.queryItems = queryParams?.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = urlComponents?.url else {
            return Single.error(NetworkError.invalidUrl)
        }

        return networkManager.fetch(url: url)
    }
}

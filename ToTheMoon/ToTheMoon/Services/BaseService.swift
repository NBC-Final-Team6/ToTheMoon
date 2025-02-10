//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/10/25.
//

import Foundation
import RxSwift

class BaseService {
    let baseURL: String
    
    init(baseURL: String) {
        self.baseURL = baseURL
    }

    func request<T: Decodable>(endpoint: String) -> Single<T> {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return Single.error(NetworkError.invalidUrl)
        }
        return NetworkManager.shared.fetch(url: url)
    }
}

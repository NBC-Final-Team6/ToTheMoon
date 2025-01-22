//
//  NetworkMan.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import Foundation
import UIKit
import RxSwift

enum NetworkError: Error {
    case invalidUrl
    case dataFetchFail
    case decodingFail
}

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    func fetch<T: Decodable>(url: URL) -> Single<T> {
        return Single.create { observer in
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    observer(.failure(error))
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    observer(.failure(NetworkError.dataFetchFail))
                    return
                }
                guard let data = data else {
                    observer(.failure(NetworkError.dataFetchFail))
                    return
                }
                do {
                    let decodedData = try JSONDecoder().decode(T.self, from: data)
                    observer(.success(decodedData))
                } catch {
                    observer(.failure(NetworkError.decodingFail))
                }
            }
            task.resume()
            return Disposables.create {
                task.cancel()
            }
        }
    }
}


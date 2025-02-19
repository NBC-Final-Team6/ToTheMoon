//
//  NetworkMan.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import Foundation
import RxSwift

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    func fetch<T: Decodable>(url: URL) -> Single<T> {
        return Single.create { observer in
            
            
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    observer(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response")
                    observer(.failure(NetworkError.dataFetchFail))
                    return
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    if let data = data, let errorMessage = String(data: data, encoding: .utf8) {
                        print("❌ Server error [\(httpResponse.statusCode)]: \(errorMessage)")
                    } else {
                        print("❌ Server error [\(httpResponse.statusCode)]: No error message")
                    }
                    observer(.failure(NetworkError.dataFetchFail))
                    return
                }
                
                guard let data = data else {
                    print("❌ No data received from server")
                    observer(.failure(NetworkError.dataFetchFail))
                    return
                }
                
                do {
                    let decodedData = try JSONDecoder().decode(T.self, from: data)
                    observer(.success(decodedData))
                } catch {
                    print("❌ JSON Decoding Error: \(error.localizedDescription)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📝 Response JSON: \(jsonString)")
                    }
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


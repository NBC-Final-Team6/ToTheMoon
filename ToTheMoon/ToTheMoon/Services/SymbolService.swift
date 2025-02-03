//
//  FetchCoinData.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/22/25.
//

import Foundation
import RxSwift
import UIKit

final class SymbolService {
    private let networkManager = NetworkManager.shared
    private let baseURL = APIEndpoint.coinGecko.baseURL
    
    /// 기존에 있던 fetchCoinData
    /// struct SymbolData: Decodable {
    ///    let id: String
    ///    let symbol: String
    ///    let name: String
    ///    let image: SymbolImage?
    ///    let description: Description
    /// }
    func fetchCoinDataAll(coinSymbol: String) -> Single<SymbolData> {
           let endpoint = "\(baseURL)/\(coinSymbol)"
           guard let url = URL(string: endpoint) else {
               return Single.error(NetworkError.invalidUrl)
           }
           return networkManager.fetch(url: url)
       }
    
    // 코인 심볼 -> 코인 ID 매핑을 저장하는 캐시
    private var symbolToIDMap: [String: String] = [:]
    
    // 코인 ID 리스트를 가져와서 캐싱
    private func fetchCoinIDMap() -> Single<Void> {
        guard let url = URL(string: "\(baseURL)/list") else { return Single.error(NetworkError.invalidUrl) }
        return networkManager.fetch(url: url)
            .map { (coinList: [SymbolID]) in
                for coin in coinList {
                    self.symbolToIDMap[coin.symbol.lowercased()] = coin.id
                }
            }
    }

    // 코인 데이터를 가져오기 전에 ID를 찾음
    func fetchCoinData(coinSymbol: String) -> Single<SymbolData> {
        let normalizedSymbol = coinSymbol.lowercased()
        
        // 1️⃣ 캐시에 ID가 있는 경우 바로 API 요청
        if let coinID = symbolToIDMap[normalizedSymbol] {
            return fetchCoinDataByID(coinID)
        }
        // 2️⃣ 코인 ID가 없으면 /coins/list 호출 후 다시 요청
        return fetchCoinIDMap()
            .flatMap { [weak self] _ -> Single<SymbolData> in
                guard let self = self, let coinID = self.symbolToIDMap[normalizedSymbol] else {
                    return Single.error(NetworkError.invalidData)
                }
                return self.fetchCoinDataByID(coinID)
            }
        
    }
    
    // 코인 ID를 사용하여 데이터 가져오기
    private func fetchCoinDataByID(_ coinID: String) -> Single<SymbolData> {
        let endpoint = "\(baseURL)/\(coinID)"
        guard let url = URL(string: endpoint) else {
            return Single.error(NetworkError.invalidUrl)
        }
        
        return networkManager.fetch(url: url)
            .do(onSuccess: { data in
            }, onError: { error in
                print("❌ [ERROR] 코인 데이터 요청 실패: \(error.localizedDescription)")
            })
    }
    
    // 코인 썸네일 이미지 가져오기
    func fetchCoinThumbImage(coinSymbol: String) -> Single<UIImage?> {
        let normalizedSymbol = coinSymbol.lowercased()
        // 1️⃣ 먼저 캐시된 코인 ID 확인
        if let cachedCoinID = symbolToIDMap[normalizedSymbol] {
            // 먼저 메모리 & 디스크 캐시에서 이미지 확인
            if let cachedImage = CoinImageCache.shared.getImage(for: cachedCoinID) {
                return .just(cachedImage)
            }
        }
        
        // 2️⃣ 코인 ID를 가져온 후, 이미지 요청
        return fetchCoinData(coinSymbol: normalizedSymbol)
            .flatMap { [weak self] (coin: SymbolData) -> Single<UIImage?> in
                guard let self = self else { return .just(nil) }
                
                let coinID = coin.id
                
                // 3️⃣ 먼저 캐시 확인 (코인 ID 기반)
                if let cachedImage = CoinImageCache.shared.getImage(for: coinID) {
                    return .just(cachedImage)
                }
                
                // 4️⃣ 썸네일 URL이 있는지 확인 후 이미지 다운로드
                guard let thumbUrl = coin.image?.thumb, let imageUrl = URL(string: thumbUrl) else {
                    return .just(ImageRepository.getImage(for: coinID)) // 기본 이미지 반환
                }
                
                return self.downloadImage(from: imageUrl)
                    .do(onSuccess: { image in
                        if let image = image {
                            CoinImageCache.shared.setImage(for: coinID, image: image)
                        } else {
                        }
                    }, onError: { error in
                        print("❌ [ERROR] 이미지 다운로드 중 오류 발생: \(error.localizedDescription)")
                    })
                    .catchAndReturn(ImageRepository.getImage(for: coinID)) // 기본 이미지 반환
            }
    }
    
    // 이미지 다운로드 메서드
    private func downloadImage(from url: URL) -> Single<UIImage?> {
        print(url)
        return Single.create { single in
            let task = URLSession.shared.dataTask(with: url) { data, _, error in
                if let error = error {
                    print("이미지 다운로드 실패: \(error)")
                    single(.success(nil))
                    return
                }
                if let data = data, let image = UIImage(data: data) {
                    single(.success(image))
                } else {
                    single(.success(nil))
                }
            }
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
}

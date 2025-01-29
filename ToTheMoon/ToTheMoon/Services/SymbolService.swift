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
    
    
    func fetchCoinData(coinSymbol: String) -> Single<SymbolData> {
        let endpoint = "\(baseURL)/\(coinSymbol)"
        guard let url = URL(string: endpoint) else {
            return Single.error(NetworkError.invalidUrl)
        }
        return networkManager.fetch(url: url)
    }
    
    func fetchCoinThumbImage(coinSymbol: String) -> Single<UIImage?> {
            let normalizedSymbol = coinSymbol.uppercased()
            
            // 1. 캐시 확인 (있으면 즉시 반환)
            if let cachedImage = CoinImageCache.shared.getImage(for: normalizedSymbol) {
                return .just(cachedImage)
            }
            
            // 2. API 요청 후 이미지 다운로드 및 캐시 저장
            let endpoint = "\(baseURL)/\(coinSymbol)"
            guard let url = URL(string: endpoint) else {
                return .just(ImageRepository.getImage(for: normalizedSymbol)) // 기본 이미지 반환
            }
            
            return fetchCoinData(coinSymbol: coinSymbol)
                .flatMap { (coin: SymbolData) -> Single<UIImage?> in
                    guard let thumbUrl = coin.image?.thumb, let imageUrl = URL(string: thumbUrl) else {
                        return .just(ImageRepository.getImage(for: normalizedSymbol)) // 기본 이미지 반환
                    }
                    
                    return self.downloadImage(from: imageUrl)
                        .do(onSuccess: { image in
                            if let image = image {
                                CoinImageCache.shared.setImage(for: normalizedSymbol, image: image)
                            }
                        })
                        .catchAndReturn(ImageRepository.getImage(for: normalizedSymbol)) // 기본 이미지 반환
                }
        }
        
        private func downloadImage(from url: URL) -> Single<UIImage?> {
            return Single.create { single in
                let task = URLSession.shared.dataTask(with: url) { data, _, error in
                    if let error = error {
                        print("이미지 다운로드 실패: \(error)")
                        single(.success(nil)) // 실패 시 nil 반환
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

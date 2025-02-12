//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/28/25.
//

import Foundation
import RxSwift
import UIKit

final class GetMarketPricesUseCase {
    private let services: [ServiceProtocol]
    private let symbolService: SymbolService
    private let symbolFormatter: SymbolFormatter

    init(
        services: [ServiceProtocol],
        symbolService: SymbolService
    ) {
        self.services = services
        self.symbolService = symbolService
        self.symbolFormatter = SymbolFormatter()
    }
    
    func execute() -> Single<[MarketPrice]> {
        let priceObservables = services.map { $0.fetchMarketPrices() }
        
        return Single.zip(priceObservables)
            .map { $0.flatMap { $0 } } // 모든 거래소 데이터 병합
            .flatMap { [weak self] allPrices in
                guard let self = self else { return .just([]) }
                return self.attachImages(to: allPrices)
            }
    }
    
    private func attachImages(to prices: [MarketPrice]) -> Single<[MarketPrice]> {
        let imageRequests = prices.map { marketPrice -> Single<MarketPrice> in
            let normalizedSymbol = symbolFormatter.format(symbol: marketPrice.symbol).uppercased()
            
            var updatedMarketPrice = marketPrice
            updatedMarketPrice.symbol = normalizedSymbol
            
            if let cachedImage = ImageRepository.getImage(for: normalizedSymbol) {
                updatedMarketPrice.image = cachedImage
                return Single.just(updatedMarketPrice)
            }
            
            return fetchAndCacheImage(for: normalizedSymbol)
                .map { image in
                    updatedMarketPrice.image = image
                    return updatedMarketPrice
                }
        }
        
        return Single.zip(imageRequests)
    }
    
    private func fetchAndCacheImage(for symbol: String) -> Single<UIImage?> {
        return symbolService.fetchCoinThumbImage(coinSymbol: symbol)
            .do(onSuccess: { image in
                if let image = image {
                    CoinImageCache.shared.setImage(for: symbol, image: image)
                }
            })
            .catchAndReturn(nil)
    }
}

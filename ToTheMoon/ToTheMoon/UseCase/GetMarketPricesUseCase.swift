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
    
    init(
        services: [ServiceProtocol] = [BithumbService(), CoinOneService(), KorbitService(), UpbitService()],
        symbolService: SymbolService = SymbolService()
    ) {
        self.services = services
        self.symbolService = symbolService
    }
    
    func execute() -> Single<[MarketPrice]> {
        let priceObservables = services.map { $0.fetchMarketPrices() }
        
        let symbolFormatter = SymbolFormatter()
        
        return Single.zip(priceObservables)
            .flatMap { [weak self] marketPricesArray -> Single<[MarketPrice]> in
                guard let self = self else { return .just([]) }
                
                let allPrices = marketPricesArray.flatMap { $0 }
                
                var imageRequests: [String: Single<UIImage?>] = [:]
                
                let updatedMarketPrices = allPrices.map { marketPrice -> Single<MarketPrice> in
                    let normalizedSymbol = symbolFormatter.format(symbol: marketPrice.symbol).uppercased()
                    
                    var updatedMarketPrice = MarketPrice(
                        symbol: normalizedSymbol,
                        price: marketPrice.price,
                        exchange: marketPrice.exchange,
                        change: marketPrice.change,
                        changeRate: marketPrice.changeRate,
                        quoteVolume: marketPrice.quoteVolume,
                        highPrice: marketPrice.highPrice,
                        lowPrice: marketPrice.lowPrice,
                        image: nil
                    )
                    
                    if let cachedImage = ImageRepository.getImage(for: normalizedSymbol) {
                        updatedMarketPrice.image = cachedImage
                        return Single.just(updatedMarketPrice)
                    }
                    
                    if let existingRequest = imageRequests[normalizedSymbol] {
                        return existingRequest.map { image in
                            updatedMarketPrice.image = image
                            return updatedMarketPrice
                        }
                    }
                    
                    let imageRequest = self.symbolService.fetchCoinThumbImage(coinSymbol: normalizedSymbol)
                        .do(onSuccess: { image in
                            if let image = image {
                                CoinImageCache.shared.setImage(for: normalizedSymbol, image: image)
                            }
                        })
                        .catchAndReturn(nil)
                    
                    imageRequests[normalizedSymbol] = imageRequest
                    
                    return imageRequest.map { image in
                        updatedMarketPrice.image = image
                        return updatedMarketPrice
                    }
                }
                
                return Single.zip(updatedMarketPrices)
            }
    }
}

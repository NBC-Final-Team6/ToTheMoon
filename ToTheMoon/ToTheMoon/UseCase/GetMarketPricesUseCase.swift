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
    private let bithumbService: BithumbService
    private let coinOneService: CoinOneService
    private let korbitService: KorbitService
    private let upbitService: UpbitService
    private let symbolService: SymbolService
    
    init(
        bithumbService: BithumbService = BithumbService(),
        coinOneService: CoinOneService = CoinOneService(),
        korbitService: KorbitService = KorbitService(),
        upbitService: UpbitService = UpbitService(),
        symbolService: SymbolService = SymbolService()
    ) {
        self.bithumbService = bithumbService
        self.coinOneService = coinOneService
        self.korbitService = korbitService
        self.upbitService = upbitService
        self.symbolService = symbolService
    }
    
    func execute() -> Single<[MarketPrice]> {
        let bithumbPrices = bithumbService.fetchMarketPrices()
        let coinOnePrices = coinOneService.fetchMarketPrices()
        let korbitPrices = korbitService.fetchMarketPrices()
        let upbitPrices = upbitService.fetchMarketPrices()
        
        let symbolFormatter = SymbolFormatter()
        
        return Single.zip(bithumbPrices, coinOnePrices, korbitPrices, upbitPrices)
            .flatMap { [weak self] bithumb, coinOne, korbit, upbit -> Single<[MarketPrice]> in
                guard let self = self else { return .just([]) }
                
                let allPrices = bithumb + coinOne + korbit + upbit
                
                // ✅ 중복 요청 방지를 위한 Dictionary
                var imageRequests: [String: Single<UIImage?>] = [:]
                
                let updatedMarketPrices = allPrices.map { marketPrice -> Single<MarketPrice> in
                    // ✅ 심볼 정규화 적용
                    let normalizedSymbol = symbolFormatter.format(symbol: marketPrice.symbol)
                    
                    // ✅ 정규화된 심볼을 기반으로 새로운 MarketPrice 객체 생성
                    var updatedMarketPrice = MarketPrice(
                        symbol: normalizedSymbol.uppercased(),
                        price: marketPrice.price,
                        exchange: marketPrice.exchange,
                        change: marketPrice.change,
                        changeRate: marketPrice.changeRate,
                        quoteVolume: marketPrice.quoteVolume ,
                        highPrice: marketPrice.highPrice,
                        lowPrice: marketPrice.lowPrice,
                        image: nil // 초기 이미지 없음
                    )
                    
                    // 1. 이미지 캐시 확인
                    if let defaultImage = ImageRepository.getImage(for: normalizedSymbol) {
                        updatedMarketPrice.image = defaultImage
                        return Single.just(updatedMarketPrice)
                    }
                    
                    // 2. 같은 심볼에 대한 요청이 이미 생성되었는지 확인
                    if let existingRequest = imageRequests[normalizedSymbol] {
                        return existingRequest.map { image in
                            updatedMarketPrice.image = image
                            return updatedMarketPrice
                        }
                    }
                    
                    // 3. 새로운 네트워크 요청 생성
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

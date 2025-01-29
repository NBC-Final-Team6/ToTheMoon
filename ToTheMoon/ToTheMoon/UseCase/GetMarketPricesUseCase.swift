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
                
                let imageRequests = allPrices.map { marketPrice in
                    let normalizedSymbol = symbolFormatter.format(symbol: marketPrice.symbol)
                    
                    //print(normalizedSymbol)
                    
                    // 1. 기본 이미지 먼저 적용
                    var updatedMarketPrice = marketPrice
                    updatedMarketPrice.image = ImageRepository.getImage(for: normalizedSymbol)
                    
                    // 2. 기본 이미지가 없는 경우에만 네트워크 요청
                    return self.symbolService.fetchCoinThumbImage(coinSymbol: normalizedSymbol)
                        .map { image in
                            if let image = image {
                                updatedMarketPrice.image = image
                                CoinImageCache.shared.setImage(for: normalizedSymbol, image: image) // 캐시에 저장
                            }
                            return updatedMarketPrice
                        }
                        .catchAndReturn(updatedMarketPrice) // 에러 발생 시 변경 없이 반환
                }
                
                return Single.zip(imageRequests)
            }
    }
}

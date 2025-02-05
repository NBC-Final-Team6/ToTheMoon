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
    
    func execute() -> Single<[(MarketPrice, [Candle])]> {
        let bithumbPrices = bithumbService.fetchMarketPrices()
        let coinOnePrices = coinOneService.fetchMarketPrices()
        let korbitPrices = korbitService.fetchMarketPrices()
        let upbitPrices = upbitService.fetchMarketPrices()
        
        let symbolFormatter = SymbolFormatter()
        
        return Single.zip(bithumbPrices, coinOnePrices, korbitPrices, upbitPrices)
            .flatMap { [weak self] bithumb, coinOne, korbit, upbit -> Single<[(MarketPrice, [Candle])]> in
                guard let self = self else { return .just([]) }
                
                let allPrices = bithumb + coinOne + korbit + upbit
                
                // ✅ 중복 이미지 요청 방지를 위한 Dictionary
                var imageRequests: [String: Single<UIImage?>] = [:]
                
                // ✅ 코인별 캔들 데이터 요청을 위한 배열
                var combinedRequests: [Single<(MarketPrice, [Candle])>] = []
                
                for marketPrice in allPrices {
                    // ✅ 심볼 정규화 적용
                    let normalizedSymbol = symbolFormatter.format(symbol: marketPrice.symbol).uppercased()
                    
                    // ✅ 새로운 MarketPrice 객체 생성 (초기 이미지 없음)
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
                    
                    // ✅ 1. 이미지 캐시 확인
                    if let cachedImage = ImageRepository.getImage(for: normalizedSymbol) {
                        updatedMarketPrice.image = cachedImage
                    } else {
                        // ✅ 2. 같은 심볼에 대한 요청이 이미 존재하는지 확인
                        if let existingRequest = imageRequests[normalizedSymbol] {
                            _ = existingRequest.map { image in
                                updatedMarketPrice.image = image
                            }
                        } else {
                            // ✅ 3. 새로운 이미지 요청
                            let imageRequest = self.symbolService.fetchCoinThumbImage(coinSymbol: normalizedSymbol)
                                .do(onSuccess: { image in
                                    if let image = image {
                                        CoinImageCache.shared.setImage(for: normalizedSymbol, image: image)
                                    }
                                })
                                .catchAndReturn(nil)
                            
                            imageRequests[normalizedSymbol] = imageRequest
                            
                            _ = imageRequest.map { image in
                                updatedMarketPrice.image = image
                            }
                        }
                    }
                    
                    // ✅ 4. 캔들 데이터 요청
                    let candleService: Single<[Candle]>
                    switch marketPrice.exchange {
                    case "Upbit":
                        candleService = self.upbitService.fetchCandles(symbol: normalizedSymbol, interval: .minute, count: 1440)
                            .delay(.milliseconds(300), scheduler: MainScheduler.instance) // ✅ 300ms 딜레이 추가
                                .retry(2) // ✅ 실패 시 최대 2번 더 재시도
                                .do(onSuccess: { candles in
                                    print("✅ \(marketPrice.exchange) 캔들 데이터 개수: \(candles.count)")
                                }, onError: { error in
                                    print("❌ \(marketPrice.exchange) 캔들 데이터 로드 실패: \(error.localizedDescription)")
                                })
                    case "Bithumb":
                        candleService = self.bithumbService.fetchCandles(symbol: normalizedSymbol, interval: .minute, count: 1440)
                    case "CoinOne":
                        candleService = self.coinOneService.fetchCandles(symbol: normalizedSymbol, interval: .minute, count: 1440)
                    case "Korbit":
                        candleService = self.korbitService.fetchCandles(symbol: normalizedSymbol, interval: .minute, count: 1440)
                    default:
                        print("⚠️ 알 수 없는 거래소: \(marketPrice.exchange), 빈 캔들 데이터 반환")
                        candleService = .just([])
                    }
                    
                    let combinedRequest = candleService
                        .map { candles in
                            return (updatedMarketPrice, candles)
                        }
                        .catchAndReturn((updatedMarketPrice, [])) // 오류 발생 시 빈 배열 반환
                    
                    combinedRequests.append(combinedRequest)
                }
                
                return Single.zip(combinedRequests)
            }
    }
}

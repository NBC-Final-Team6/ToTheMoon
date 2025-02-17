//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/14/25.
//
import Foundation
import RxSwift
import UIKit
final class FetchFavoriteCoinsUseCase {
    private let webSocketServices: [WebSocketServiceProtocol]
    private let manageFavoritesUseCase: ManageFavoritesUseCaseProtocol
    private let symbolFormatter: SymbolFormatter
    private var disposeBag = DisposeBag()
    
    init(manageFavoritesUseCase: ManageFavoritesUseCaseProtocol, webSocketServices: [WebSocketServiceProtocol]) {
        self.manageFavoritesUseCase = manageFavoritesUseCase
        self.webSocketServices = webSocketServices
        self.symbolFormatter = SymbolFormatter()
        observeFavoriteCoins()
    }
    
    private func observeFavoriteCoins() {
        manageFavoritesUseCase.fetchFavoriteCoins()
            .distinctUntilChanged { $0 == $1 }
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                print("🔄 관심 코인 목록 변경 감지됨 → 웹소켓 재구독 실행")
                self?.fetchFavoriteCoinsRealtimeData()
            })
            .disposed(by: disposeBag)
    }
    
    func fetchFavoriteCoinsRealtimeData() -> Observable<[MarketPrice]> {
        let coreDataObservable = manageFavoritesUseCase.fetchFavoriteCoins()
            .do(onNext: { coreDataPrices in
                print("🟠 [DEBUG] CoreData에서 가져온 관심 코인 리스트:")
                coreDataPrices.forEach { print("   💾 \( $0.exchange) - \( $0.symbol): \( $0.price) KRW") }
            })
        let webSocketObservable = manageFavoritesUseCase.fetchFavoriteCoins()
            .flatMapLatest { [weak self] favoriteCoins -> Observable<[MarketPrice]> in
                guard let self = self else { return Observable.just([]) }
                print("🟢 [DEBUG] 관심 코인 리스트:")
                favoriteCoins.forEach { coin in
                    print("   🔹 \(coin.exchange) - \(coin.symbol)")
                }
                var symbolsByExchange: [Exchange: [String]] = [:]
                for coin in favoriteCoins {
                    guard let exchange = Exchange(rawValue: coin.exchange.lowercased()) else {
                        continue
                    }
                    let symbol = coin.symbol.uppercased() // Optional 바인딩 불필요
                    symbolsByExchange[exchange, default: []].append(symbol)
                }
                print("🟡 [DEBUG] 거래소별 심볼 매핑:")
                symbolsByExchange.forEach { exchange, symbols in
                    print("   🔸 \(exchange.rawValue): \(symbols)")
                }
                var marketPricesByExchange: [Exchange: [String: MarketPrice]] = [:]
                let observables = self.webSocketServices.map { service -> Observable<[MarketPrice]> in
                    if let symbols = symbolsByExchange[service.exchange], !symbols.isEmpty {
                        print("🔵 [DEBUG] \(service.exchange.rawValue) 웹소켓 요청 시작 → 심볼: \(symbols)")
                        
                        return service.fetchKrwTicker(for: symbols)
                            .flatMap { [weak self] prices in
                                guard let self = self else { return Observable.just(prices) }
                                return self.attachImages(to: prices)
                            }
                            .do(onNext: { prices in
                                print("🟣 [DEBUG] \(service.exchange.rawValue) 웹소켓 응답 데이터:")
                                prices.forEach { print("   💰 \( $0.exchange) - \( $0.symbol): \( $0.price) KRW") }
                            }, onError: { error in
                                print("🚨 [DEBUG] \(service.exchange.rawValue) 웹소켓 에러 발생: \(error.localizedDescription)")
                            })
                            .map { newPrices -> [MarketPrice] in
                                var updatedPrices = marketPricesByExchange[service.exchange] ?? [:]
                                newPrices.forEach { price in
                                    updatedPrices[price.symbol] = price
                                }
                                marketPricesByExchange[service.exchange] = updatedPrices
                                return Array(updatedPrices.values)
                            }
                    } else {
                        print("⚠️ [DEBUG] \(service.exchange.rawValue) 관심 목록이 없음 → 웹소켓 해제")
                        service.fetchKrwTicker(for: [])
                        return Observable.just([])
                    }
                }
                return Observable.combineLatest(observables)
                    .map { allPrices in allPrices.flatMap { $0 } }
            }
        
        return Observable.concat(coreDataObservable, webSocketObservable)
    }
    
    private func attachImages(to prices: [MarketPrice]) -> Observable<[MarketPrice]> {
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
        
        return Single.zip(imageRequests).asObservable()
    }
    
    private func fetchAndCacheImage(for symbol: String) -> Single<UIImage?> {
        return SymbolService().fetchCoinThumbImage(coinSymbol: symbol)
            .do(onSuccess: { image in
                if let image = image {
                    CoinImageCache.shared.setImage(for: symbol, image: image)
                }
            })
            .catchAndReturn(nil)
    }
    func cancelSubscriptions() {
        disposeBag = DisposeBag()
        webSocketServices.forEach { $0.disconnectWebSocket() }
        print("🔴 모든 웹소켓 구독 해제됨")
    }
}



//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/14/25.
//

import Foundation
import RxSwift

final class FetchFavoriteCoinsUseCase {
    private let webSocketServices: [WebSocketServiceProtocol]
    private let manageFavoritesUseCase: ManageFavoritesUseCaseProtocol
    private var disposeBag = DisposeBag()
    
    init(manageFavoritesUseCase: ManageFavoritesUseCaseProtocol, webSocketServices: [WebSocketServiceProtocol]) {
        self.manageFavoritesUseCase = manageFavoritesUseCase
        self.webSocketServices = webSocketServices
        observeFavoriteCoins()
    }
    
    private func observeFavoriteCoins() {
        manageFavoritesUseCase.fetchFavoriteCoins()
            .distinctUntilChanged { $0 == $1 } // 같은 값이면 무시
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance) // 변경 감지 후 300ms 지연
            .subscribe(onNext: { [weak self] _ in
                print("🔄 관심 코인 목록 변경 감지됨 → 웹소켓 재구독 실행")
                self?.fetchFavoriteCoinsRealtimeData()
            })
            .disposed(by: disposeBag)
    }
    
    
    // ToDo: 거래소 마다 1개 코인 데이터만 셀에서 보임, 코어 데이터에 없으면 요청 끊어야함 ...
    func fetchFavoriteCoinsRealtimeData() -> Observable<[MarketPrice]> {
        return manageFavoritesUseCase.fetchFavoriteCoins()
            .flatMapLatest { [weak self] favoriteCoins -> Observable<[MarketPrice]> in
                guard let self = self else { return Observable.just([]) }

                print("🟢 [DEBUG] 관심 코인 리스트:")
                favoriteCoins.forEach { coin in
                    print("   🔹 \(coin.exchangename ?? "nil") - \(coin.symbol ?? "nil")")
                }

                // 거래소별 코인 심볼을 분류
                var symbolsByExchange: [Exchange: [String]] = [:]
                for coin in favoriteCoins {
                    guard let exchange = Exchange(rawValue: coin.exchangename?.lowercased() ?? ""),
                          let symbol = coin.symbol?.uppercased() else {
                        continue
                    }
                    symbolsByExchange[exchange, default: []].append(symbol)
                }

                print("🟡 [DEBUG] 거래소별 심볼 매핑:")
                symbolsByExchange.forEach { exchange, symbols in
                    print("   🔸 \(exchange.rawValue): \(symbols)")
                }

                // ✅ 거래소별, 코인별 데이터를 개별적으로 관리하기 위한 딕셔너리
                var marketPricesByExchange: [Exchange: [String: MarketPrice]] = [:]

                let observables = self.webSocketServices.map { service -> Observable<[MarketPrice]> in
                    if let symbols = symbolsByExchange[service.exchange], !symbols.isEmpty {
                        print("🔵 [DEBUG] \(service.exchange.rawValue) 웹소켓 요청 시작 → 심볼: \(symbols)")
                        
                        return service.fetchKrwTicker(for: symbols)
                            .do(onNext: { prices in
                                print("🟣 [DEBUG] \(service.exchange.rawValue) 웹소켓 응답 데이터:")
                                prices.forEach { price in
                                    print("   💰 \(price.exchange) - \(price.symbol): \(price.price) KRW")
                                }
                            }, onError: { error in
                                print("🚨 [DEBUG] \(service.exchange.rawValue) 웹소켓 에러 발생: \(error.localizedDescription)")
                            })
                            .map { newPrices -> [MarketPrice] in
                                // ✅ 기존 데이터를 유지하면서 새로운 데이터를 갱신
                                var updatedPrices = marketPricesByExchange[service.exchange] ?? [:]
                                newPrices.forEach { price in
                                    updatedPrices[price.symbol] = price
                                }
                                marketPricesByExchange[service.exchange] = updatedPrices
                                return Array(updatedPrices.values) // ✅ 변환하여 Observable로 반환
                            }
                    } else {
                        print("⚠️ [DEBUG] \(service.exchange.rawValue) 관심 목록이 없음 → 웹소켓 해제")
                        service.fetchKrwTicker(for: []) // 해당 거래소 웹소켓 해제
                        return Observable.just([]) // 빈 Observable 반환
                    }
                }

                // ✅ 모든 거래소 데이터를 합쳐서 반환
                return Observable.combineLatest(observables)
                    .map { allPrices in
                        return allPrices.flatMap { $0 } // ✅ 여러 거래소 데이터를 하나의 리스트로 병합
                    }
            }
    }
    
    func cancelSubscriptions() {
        disposeBag = DisposeBag() // ✅ 모든 구독 해제
        webSocketServices.forEach { $0.disconnectWebSocket() } // ✅ 웹소켓 해제 추가
        print("🔴 모든 웹소켓 구독 해제됨")
    }
    
    
}

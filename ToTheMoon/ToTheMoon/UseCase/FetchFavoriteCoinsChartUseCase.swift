//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/17/25.
//
import Foundation
import RxSwift
// 관심 코인의 차트 데이터를 가져오는 유즈케이스
final class FetchFavoriteCoinsChartUseCase {
    private let exchangeServices: [ServiceProtocol] // 거래소 API 서비스 리스트
    private let manageFavoritesUseCase: ManageFavoritesUseCaseProtocol
    private var disposeBag = DisposeBag()
    
    init(
        manageFavoritesUseCase: ManageFavoritesUseCaseProtocol,
        exchangeServices: [ServiceProtocol]
    ) {
        self.manageFavoritesUseCase = manageFavoritesUseCase
        self.exchangeServices = exchangeServices
    }
    
    // 코어데이터에서 관심 코인의 거래소 및 심볼 조회 → 각 거래소 API에서 캔들 데이터 요청
    func fetchFavoriteCoinsChartData(interval: CandleInterval, count: Int) -> Observable<[Candle]> {
        return manageFavoritesUseCase.fetchFavoriteCoins()
            .flatMapLatest { [weak self] favoriteCoins -> Observable<[Candle]> in
                guard let self = self else { return Observable.just([]) }
                var symbolsByExchange: [Exchange: [String]] = [:]
                for coin in favoriteCoins {
                    guard let exchange = Exchange(rawValue: coin.exchange.lowercased()) else {
                        continue
                    }
                    let symbol = coin.symbol.uppercased()
                    symbolsByExchange[exchange, default: []].append(symbol)
                }
                let observables = self.exchangeServices.map { service -> Observable<[Candle]> in
                    guard let symbols = symbolsByExchange[service.exchange], !symbols.isEmpty else {
                        return Observable.just([])
                    }
                    
                    let candleObservables = symbols.map { symbol in
                        service.fetchCandles(symbol: symbol, interval: interval, count: count)
                            .catchAndReturn([]) // 에러 발생 시 빈 데이터 반환
                            .asObservable() // Single을 Observable로 변환
                    }
                    
                    return Observable.combineLatest(candleObservables)
                        .map { $0.flatMap { $0 } } // 모든 캔들 데이터를 하나의 배열로 합침
                }
                
                return Observable.combineLatest(observables)
                    .map { $0.flatMap { $0 } } // 최종적으로 모든 거래소의 데이터를 합쳐 반환
            }
            .do(onNext: { candles in
                print("📊 [DEBUG] 관심 코인 차트 데이터 수신 완료: \(candles.count)개")
                candles.forEach { candle in
                    print("   🔹 \(candle.symbol) - Open: \(candle.open), Close: \(candle.close)")
                }
            }, onError: { error in
                print("🚨 [DEBUG] 차트 데이터 가져오기 실패: \(error.localizedDescription)")
            })
    }
}


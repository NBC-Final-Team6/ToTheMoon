//
//  CoinPriceViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import Foundation
import RxSwift
import RxCocoa

class CoinPriceViewModel {
    
    private let disposeBag = DisposeBag()
    
    private let upbitService = UpbitService()
    private let bithumbService = BithumbService()
    private let coinoneService = CoinOneService()
    private let korbitService = KorbitService()
    
    private var currentExchange: Exchange = .upbit
    private var timer: Disposable?
    
    // Output
    private(set) var coinPrices = BehaviorRelay<[MarketPrice]>(value: [])
    let selectedCoinPrice = PublishSubject<MarketPrice>()
    let error = PublishSubject<Error>()
    
    init() {
        setupTimer()
    }
    
    deinit {
        timer?.dispose()
    }
    
    // 거래소 변경
    func selectExchange(_ exchange: Exchange) {
        currentExchange = exchange
        fetchCoinPrices()
    }
    
    // 코인 선택
    func selectCoinPrice(at index: Int) {
        guard index < coinPrices.value.count else { return }
        selectedCoinPrice.onNext(coinPrices.value[index])
    }
    
    // 타이머 설정
    private func setupTimer() {
        timer?.dispose()
        timer = Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.fetchCoinPrices()
            })
        
        timer?.disposed(by: disposeBag)
    }
    
    // 코인명만 보이게(KRW 글자 제외)
    private func extractCoinSymbol(_ symbol: String) -> String {
        let formatter = SymbolFormatter()
        return formatter.format(symbol: symbol)
    }
    
    // 코인 가격 데이터 가져오기
    private func fetchCoinPrices() {
        
        let service: Single<[MarketPrice]>
        
        switch currentExchange {
        case .upbit:
            service = upbitService.fetchMarketPrices()
        case .bithumb:
            service = bithumbService.fetchMarketPrices()
        case .coinone:
            service = coinoneService.fetchMarketPrices()
        case .korbit:
            service = korbitService.fetchMarketPrices()
        }
        
        service
            .map { marketPrices -> [MarketPrice] in
                marketPrices.map { price in
                    var modifiedPrice = price
                    modifiedPrice.symbol = self.extractCoinSymbol(price.symbol)
                    return modifiedPrice
                }
                .sorted { $0.quoteVolume > $1.quoteVolume }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] marketPrices in
                self?.coinPrices.accept(marketPrices)
            }, onFailure: { [weak self] error in
                self?.error.onNext(error)
            })
            .disposed(by: disposeBag)
    }
}

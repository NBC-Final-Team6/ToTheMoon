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
    
    // 코인 가격 데이터 가져오기
    private func fetchCoinPrices() {
        
        upbitService.fetchMarketPrices()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] marketPrices in
                self?.coinPrices.accept(marketPrices)
            }, onFailure: { [weak self] error in
                self?.error.onNext(error)
            })
            .disposed(by: disposeBag)
    }
}

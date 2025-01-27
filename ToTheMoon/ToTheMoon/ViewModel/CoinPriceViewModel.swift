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
    
    // Output
    private(set) var coinPrices: BehaviorRelay<[CoinPrice]>
    let selectedCoinPrice = PublishSubject<CoinPrice>()
    
    init() {
        let mockPrices = [
            CoinPrice(coinName: "비트코인", marketName: "업비트", price: 1600000000.0, priceChange: 1),
            CoinPrice(coinName: "이더리움", marketName: "빗썸", price: 160000.0, priceChange: -0.4),
            CoinPrice(coinName: "리플", marketName: "코인원", price: 800.0, priceChange: 0.2)
        ]
        
        coinPrices = BehaviorRelay(value: mockPrices)
    }
    
    func selectCoinPrice(at index: Int) {
        guard index < coinPrices.value.count else { return }
        selectedCoinPrice.onNext(coinPrices.value[index])
    }
}

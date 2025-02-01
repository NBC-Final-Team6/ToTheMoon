//
//  FavoritesViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import RxSwift
import RxCocoa

final class PopularCurrencyViewModel {
    private let getMarketPricesUseCase: GetMarketPricesUseCase
    private let disposeBag = DisposeBag()

    let popularCoins = BehaviorRelay<[MarketPrice]>(value: [])

    init(getMarketPricesUseCase: GetMarketPricesUseCase = GetMarketPricesUseCase()) {
        self.getMarketPricesUseCase = getMarketPricesUseCase
    }

    func fetchPopularCoins() {
        getMarketPricesUseCase.execute()
            .map { marketPrices in
                // 거래 금액(quoteVolume) 기준으로 내림차순 정렬
                return marketPrices.sorted(by: { $0.quoteVolume > $1.quoteVolume })
            }
            .subscribe(onSuccess: { [weak self] sortedCoins in
                self?.popularCoins.accept(sortedCoins)
            }, onFailure: { error in
                print("❌ 인기 코인 데이터 가져오기 실패: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
}

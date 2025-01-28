//
//  FavoritesViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import RxSwift
import RxCocoa

final class FavoritesListViewModel {
    private let service = BithumbService()
    private let disposeBag = DisposeBag()
    
    //관심 목록 데이터
    let favoritesCoins = BehaviorRelay<[MarketPrice]>(value: [])
    
    func fetchfavoritesCoins() {
        service.fetchMarketPrices()
            .map { marketPrices in
                // 거래 금액(totalPrice)을 기준으로 오름차순 정렬
                marketPrices.sorted(by: { $0.quoteVolume > $1.quoteVolume })
            }
            .subscribe(onSuccess: { [weak self] sortedCoins in
                self?.favoritesCoins.accept(sortedCoins)
                print(sortedCoins)
            }, onFailure: { error in
                print("Error fetching market prices: \(error)")
            })
            .disposed(by: disposeBag)
    }
}

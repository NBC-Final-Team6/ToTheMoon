//
//  FavoritesViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import RxSwift
import RxCocoa

final class FavoritesListViewModel {
    private let manageFavoritesUseCase: ManageFavoritesUseCaseProtocol
    private let getMarketPricesUseCase: GetMarketPricesUseCase
    private let disposeBag = DisposeBag()

    private let favoriteCoinsRelay = BehaviorRelay<[MarketPrice]>(value: [])

    var favoriteCoins: Observable<[MarketPrice]> {
        return favoriteCoinsRelay.asObservable()
    }

    init(manageFavoritesUseCase: ManageFavoritesUseCaseProtocol, getMarketPricesUseCase: GetMarketPricesUseCase) {
        self.manageFavoritesUseCase = manageFavoritesUseCase
        self.getMarketPricesUseCase = getMarketPricesUseCase
        fetchFavoriteCoins()
    }

    func fetchFavoriteCoins() {
        let savedCoinsObservable = manageFavoritesUseCase.fetchFavoriteCoins()
            .map { savedCoins in
                // ✅ UUID 값을 기준으로 오름차순 정렬
                return savedCoins.sorted { $0.id?.uuidString ?? "" < $1.id?.uuidString ?? "" }
            }
            .asObservable()
        
        let allMarketPricesSingle = getMarketPricesUseCase.execute()
        
        Observable.combineLatest(savedCoinsObservable, allMarketPricesSingle.asObservable())
            .map { savedCoins, marketPrices in
                // 📌 사용자의 즐겨찾기 리스트에 해당하는 코인만 필터링
                return marketPrices.filter { marketPrice in
                    savedCoins.contains { $0.symbol == marketPrice.symbol && $0.exchangename == marketPrice.exchange }
                }
            }
            .subscribe(onNext: { [weak self] filteredMarketPrices in
                self?.favoriteCoinsRelay.accept(filteredMarketPrices)
            }, onError: { error in
                print("❌ 코인 가격 가져오기 실패: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
}

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
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false) // ✅ 추가

    var favoriteCoins: Observable<[MarketPrice]> {
        return favoriteCoinsRelay.asObservable()
    }
    
    var isLoading: Observable<Bool> { // ✅ 추가
        return isLoadingRelay.asObservable()
    }

    init(manageFavoritesUseCase: ManageFavoritesUseCaseProtocol, getMarketPricesUseCase: GetMarketPricesUseCase) {
        self.manageFavoritesUseCase = manageFavoritesUseCase
        self.getMarketPricesUseCase = getMarketPricesUseCase
        fetchFavoriteCoins()
    }

    func fetchFavoriteCoins() {
        isLoadingRelay.accept(true) // ✅ 데이터 로딩 시작

        let savedCoinsObservable = manageFavoritesUseCase.fetchFavoriteCoins()
            .map { savedCoins in
                return savedCoins.sorted { $0.id?.uuidString ?? "" < $1.id?.uuidString ?? "" }
            }
            .asObservable()
        
        let allMarketPricesSingle = getMarketPricesUseCase.execute()
            .map { marketData in
                marketData.map { $0.0 } // ✅ MarketPrice만 추출하여 오류 해결
            }
        
        Observable.combineLatest(savedCoinsObservable, allMarketPricesSingle.asObservable())
            .map { savedCoins, marketPrices in
                return marketPrices.filter { marketPrice in
                    savedCoins.contains { $0.symbol == marketPrice.symbol && $0.exchangename == marketPrice.exchange }
                }
            }
            .subscribe(onNext: { [weak self] filteredMarketPrices in
                self?.favoriteCoinsRelay.accept(filteredMarketPrices)
                self?.isLoadingRelay.accept(false) // ✅ 데이터 로딩 완료
            }, onError: { error in
                print("❌ 코인 가격 가져오기 실패: \(error.localizedDescription)")
                self.isLoadingRelay.accept(false) // ✅ 오류 발생 시 로딩 상태 해제
            })
            .disposed(by: disposeBag)
    }
    
    func removeFavoriteCoin(_ coin: MarketPrice) {
         manageFavoritesUseCase.removeCoin(coin)
            .subscribe(onError: { error in
                print("❌ 즐겨찾기 코인 삭제 실패: \(error.localizedDescription)")
            }, onCompleted: { [weak self] in
                self?.fetchFavoriteCoins()
            })
             .disposed(by: disposeBag)
     }
}


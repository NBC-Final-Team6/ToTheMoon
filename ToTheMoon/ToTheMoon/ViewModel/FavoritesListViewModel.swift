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
    private let disposeBag = DisposeBag()
    private let service = BithumbService()
    
    private let favoriteCoinsRelay = BehaviorRelay<[Coin]>(value: [])
    
    var favoriteCoins: Observable<[Coin]> {
        return favoriteCoinsRelay.asObservable()
    }
    
    init(manageFavoritesUseCase: ManageFavoritesUseCaseProtocol) {
        self.manageFavoritesUseCase = manageFavoritesUseCase
        fetchFavoriteCoins()
    }
    
    func fetchFavoriteCoins() {
        manageFavoritesUseCase.fetchFavoriteCoins()
            .subscribe(onNext: { [weak self] coins in
                self?.favoriteCoinsRelay.accept(coins)
            })
            .disposed(by: disposeBag)
    }
    
    func toggleFavorite(_ marketPrice: MarketPrice) {
        let coinKey = "\(marketPrice.symbol)_\(marketPrice.exchange)"

        manageFavoritesUseCase.isCoinSaved(marketPrice.symbol, exchange: marketPrice.exchange)
            .observe(on: MainScheduler.asyncInstance) // ✅ 이벤트가 비동기적으로 실행되도록 함
            .flatMapLatest { isSaved -> Observable<Void> in
                if isSaved {
                    return self.manageFavoritesUseCase.removeCoin(marketPrice)
                } else {
                    return self.manageFavoritesUseCase.saveCoin(marketPrice)
                }
            }
            .subscribe(onNext: { [weak self] in
                self?.fetchFavoriteCoins()  // ✅ 업데이트된 즐겨찾기 리스트 불러오기
            })
            .disposed(by: disposeBag)
    }
    
    func isCoinSaved(_ symbol: String, exchange: String) -> Observable<Bool> {
        return manageFavoritesUseCase.isCoinSaved(symbol, exchange: exchange)
    }
}

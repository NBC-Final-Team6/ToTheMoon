//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/31/25.
//

import Foundation
import RxSwift

protocol ManageFavoritesUseCaseProtocol {
    func saveCoin(_ coin: MarketPrice) -> Observable<Void>
    func isCoinSaved(_ symbol: String) -> Observable<Bool>
    func fetchFavoriteCoins() -> Observable<[Coin]>
}

final class ManageFavoritesUseCase: ManageFavoritesUseCaseProtocol {
    private let coreDataManager: CoreDataManager
    
    init(coreDataManager: CoreDataManager = CoreDataManager.shared) {
        self.coreDataManager = coreDataManager
    }

    func saveCoin(_ coin: MarketPrice) -> Observable<Void> {
        return coreDataManager.createCoin(name: coin.symbol, symbol: coin.symbol, exchange: coin.exchange)
    }

    func isCoinSaved(_ symbol: String) -> Observable<Bool> {
        return coreDataManager.fetchCoins().map { coins in
            return coins.contains { $0.symbol == symbol }
        }
    }

    func fetchFavoriteCoins() -> Observable<[Coin]> {
        return coreDataManager.fetchCoins()
    }
}

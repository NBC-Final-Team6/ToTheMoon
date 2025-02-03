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
    func removeCoin(_ coin: MarketPrice) -> Observable<Void>  // ✅ 추가: 코인 삭제 기능
    func isCoinSaved(_ symbol: String, exchange: String) -> Observable<Bool>  // ✅ 수정: 거래소 정보 추가
    func fetchFavoriteCoins() -> Observable<[Coin]>
    func toggleFavorite(_ coin: MarketPrice) -> Observable<Void>  // ✅ 추가: 추가/삭제 자동 처리
}

final class ManageFavoritesUseCase: ManageFavoritesUseCaseProtocol {
    private let coreDataManager: CoreDataManager
    
    init(coreDataManager: CoreDataManager = CoreDataManager.shared) {
        self.coreDataManager = coreDataManager
    }

    /// ✅ 즐겨찾기 추가
    func saveCoin(_ coin: MarketPrice) -> Observable<Void> {
        return coreDataManager.createCoin(name: coin.symbol, symbol: coin.symbol, exchange: coin.exchange)
    }

    /// ✅ 즐겨찾기 삭제 (symbol + exchange 기반)
    func removeCoin(_ coin: MarketPrice) -> Observable<Void> {
        return coreDataManager.deleteCoin(symbol: coin.symbol, exchange: coin.exchange)
    }

    /// ✅ 즐겨찾기 여부 확인 (symbol + exchange 기반)
    func isCoinSaved(_ symbol: String, exchange: String) -> Observable<Bool> {
        return coreDataManager.fetchCoins().map { coins in
            return coins.contains { $0.symbol == symbol && $0.exchangename == exchange }
        }
    }

    /// ✅ 저장된 모든 코인 가져오기
    func fetchFavoriteCoins() -> Observable<[Coin]> {
        return coreDataManager.fetchCoins()
    }

    /// ✅ 즐겨찾기 추가/삭제 토글 (한 번 호출로 상태 변경)
    func toggleFavorite(_ coin: MarketPrice) -> Observable<Void> {
        return isCoinSaved(coin.symbol, exchange: coin.exchange)
            .flatMap { isSaved -> Observable<Void> in
                if isSaved {
                    return self.removeCoin(coin)
                } else {
                    return self.saveCoin(coin)
                }
            }
    }
}

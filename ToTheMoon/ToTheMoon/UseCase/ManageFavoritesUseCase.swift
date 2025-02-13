//
//  ManageFavoritesUseCase.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/31/25.
//

import Foundation
import RxSwift

protocol ManageFavoritesUseCaseProtocol {
    func saveCoin(_ coin: MarketPrice) -> Observable<Void>
    func removeCoin(_ coin: MarketPrice) -> Observable<Void>
    func isCoinSaved(_ symbol: String, exchange: String) -> Observable<Bool>
    func fetchFavoriteCoins() -> Observable<[Coin]>
    func toggleFavorite(_ coin: MarketPrice) -> Observable<Void>
}

final class ManageFavoritesUseCase: ManageFavoritesUseCaseProtocol {
    
    // MARK: - Dependencies
    private let coreDataManager: CoreDataManager
    
    // MARK: - Init
    init(coreDataManager: CoreDataManager = CoreDataManager.shared) {
        self.coreDataManager = coreDataManager
    }
    
    // MARK: - Public Methods

    /// ✅ 즐겨찾기 추가 (대소문자 무시 적용)
    func saveCoin(_ coin: MarketPrice) -> Observable<Void> {
        let (normalizedSymbol, normalizedExchange) = normalizeCoinInfo(symbol: coin.symbol, exchange: coin.exchange)
        return coreDataManager.createCoin(name: coin.symbol, symbol: normalizedSymbol, exchange: normalizedExchange)
    }

    /// ✅ 즐겨찾기 삭제 (대소문자 무시 적용)
    func removeCoin(_ coin: MarketPrice) -> Observable<Void> {
        let (normalizedSymbol, normalizedExchange) = normalizeCoinInfo(symbol: coin.symbol, exchange: coin.exchange)
        return coreDataManager.deleteCoin(symbol: normalizedSymbol, exchange: normalizedExchange)
    }

    /// ✅ 즐겨찾기 여부 확인 (대소문자 무시 적용)
    func isCoinSaved(_ symbol: String, exchange: String) -> Observable<Bool> {
        let (normalizedSymbol, normalizedExchange) = normalizeCoinInfo(symbol: symbol, exchange: exchange)
        
        return coreDataManager.fetchCoins()
            .map { coins in
                coins.contains {
                    self.normalizeCoinInfo(symbol: $0.symbol, exchange: $0.exchangename) == (normalizedSymbol, normalizedExchange)
                }
            }
    }

    /// ✅ 저장된 모든 코인 가져오기 (대소문자 변환 적용)
    func fetchFavoriteCoins() -> Observable<[Coin]> {
        return coreDataManager.fetchCoins()
            .map { self.normalizeCoins(coins: $0) }
    }

    /// ✅ 즐겨찾기 추가/삭제 토글 (대소문자 무시 적용)
    func toggleFavorite(_ coin: MarketPrice) -> Observable<Void> {
        let (normalizedSymbol, normalizedExchange) = normalizeCoinInfo(symbol: coin.symbol, exchange: coin.exchange)
        
        return isCoinSaved(normalizedSymbol, exchange: normalizedExchange)
            .flatMap { isSaved -> Observable<Void> in
                isSaved ? self.removeCoin(coin) : self.saveCoin(coin)
            }
    }
    
    // MARK: - Private Utility Methods
    
    /// 🔹 코인 정보(심볼, 거래소) 표준화: 대소문자 변환 + 공백 제거
    private func normalizeCoinInfo(symbol: String?, exchange: String?) -> (String, String) {
        let normalizedSymbol = symbol?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
        let normalizedExchange = exchange?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
        return (normalizedSymbol, normalizedExchange)
    }
    
    /// 🔹 저장된 코인 목록을 표준화된 형태로 변환
    private func normalizeCoins(coins: [Coin]) -> [Coin] {
        return coins.map { coin in
            coin.symbol = coin.symbol?.lowercased().trimmingCharacters(in: .whitespaces)
            coin.exchangename = coin.exchangename?.lowercased().trimmingCharacters(in: .whitespaces)
            return coin
        }
    }
}

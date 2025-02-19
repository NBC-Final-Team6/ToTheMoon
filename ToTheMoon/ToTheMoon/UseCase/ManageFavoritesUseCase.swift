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
    func fetchFavoriteCoins() -> Observable<[MarketPrice]>
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
    // 즐겨찾기 추가 (심볼 통일 적용)
    func saveCoin(_ coin: MarketPrice) -> Observable<Void> {
        let normalizedCoin = normalizeCoin(coin)
        return coreDataManager.createCoin(marketPrice: normalizedCoin)
    }

    // 즐겨찾기 삭제 (심볼 통일 적용)
    func removeCoin(_ coin: MarketPrice) -> Observable<Void> {
        let normalizedCoin = normalizeCoin(coin)
        return coreDataManager.deleteCoin(symbol: normalizedCoin.symbol, exchange: normalizedCoin.exchange)
    }

    // 즐겨찾기 여부 확인 (심볼 통일 적용)
    func isCoinSaved(_ symbol: String, exchange: String) -> Observable<Bool> {
        let normalizedSymbol = normalizeSymbol(symbol)
        let normalizedExchange = exchange.lowercased().trimmingCharacters(in: .whitespaces)
        
        return coreDataManager.fetchCoins()
            .map { coins in
                coins.contains { $0.symbol == normalizedSymbol && $0.exchange == normalizedExchange }
            }
    }

    // 저장된 모든 코인 가져오기 (심볼 통일 적용)
    func fetchFavoriteCoins() -> Observable<[MarketPrice]> {
        return coreDataManager.fetchCoins()
            .map { coins in
                return self.normalizeCoins(coins)
            }
    }

    // 즐겨찾기 추가/삭제 토글 (심볼 통일 적용)
    func toggleFavorite(_ coin: MarketPrice) -> Observable<Void> {
        let normalizedCoin = normalizeCoin(coin)
        return isCoinSaved(normalizedCoin.symbol, exchange: normalizedCoin.exchange)
            .flatMap { isSaved -> Observable<Void> in
                isSaved ? self.removeCoin(normalizedCoin) : self.saveCoin(normalizedCoin)
            }
    }
    
    // MARK: - Private Utility Methods
    
    /// **심볼 표준화 함수** (KRW-BTC, BTC_KRW, btc_krw -> BTC)
    private func normalizeSymbol(_ symbol: String?) -> String {
        guard let symbol = symbol else { return "" }
        
        let formattedSymbol = symbol
            .replacingOccurrences(of: "-", with: "_") // `KRW-BTC` -> `KRW_BTC`
            .replacingOccurrences(of: "KRW_", with: "") // `KRW_BTC` -> `BTC`
            .replacingOccurrences(of: "_KRW", with: "") // `BTC_KRW` -> `BTC`
            .replacingOccurrences(of: "/", with: "") // `BTC/KRW` -> `BTC`
            .lowercased().trimmingCharacters(in: .whitespaces)
        
        return formattedSymbol.uppercased() // 최종적으로 대문자로 변환
    }

    /// **코인 정보(심볼, 거래소) 표준화** (대소문자 변환 + 공백 제거)
    private func normalizeCoin(_ coin: MarketPrice) -> MarketPrice {
        return MarketPrice(
            symbol: normalizeSymbol(coin.symbol),
            price: coin.price,
            exchange: coin.exchange.lowercased().trimmingCharacters(in: .whitespaces),
            change: coin.change,
            changeRate: coin.changeRate,
            quoteVolume: coin.quoteVolume,
            highPrice: coin.highPrice,
            lowPrice: coin.lowPrice,
            image: coin.image
        )
    }

    /// **저장된 코인 목록을 표준화된 형태로 변환**
    private func normalizeCoins(_ coins: [MarketPrice]) -> [MarketPrice] {
        return coins.map { normalizeCoin($0) }
    }
}

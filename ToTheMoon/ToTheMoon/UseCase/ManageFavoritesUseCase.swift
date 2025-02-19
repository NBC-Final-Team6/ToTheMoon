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
    //즐겨찾기 추가 (대소문자 무시 적용)
    func saveCoin(_ coin: MarketPrice) -> Observable<Void> {
            return coreDataManager.createCoin(marketPrice: coin)
        }
    //즐겨찾기 삭제 (대소문자 무시 적용)
    func removeCoin(_ coin: MarketPrice) -> Observable<Void> {
        return coreDataManager.deleteCoin(symbol: coin.symbol, exchange: coin.exchange)
    }
    // 즐겨찾기 여부 확인 (대소문자 무시 적용)
    func isCoinSaved(_ symbol: String, exchange: String) -> Observable<Bool> {
            return coreDataManager.fetchCoins()
                .map { coins in
                    coins.contains { $0.symbol == symbol && $0.exchange == exchange }
                }
        }
    // 저장된 모든 코인 가져오기 (대소문자 변환 적용)
    func fetchFavoriteCoins() -> Observable<[MarketPrice]> {
            return coreDataManager.fetchCoins()
        }
    // 즐겨찾기 추가/삭제 토글 (대소문자 무시 적용)
    func toggleFavorite(_ coin: MarketPrice) -> Observable<Void> {
            return isCoinSaved(coin.symbol, exchange: coin.exchange)
                .flatMap { isSaved -> Observable<Void> in
                    isSaved ? self.removeCoin(coin) : self.saveCoin(coin)
                }
        }
    
    // MARK: - Private Utility Methods
    
    // 코인 정보(심볼, 거래소) 표준화: 대소문자 변환 + 공백 제거
    private func normalizeCoinInfo(symbol: String?, exchange: String?) -> (String, String) {
        let normalizedSymbol = symbol?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
        let normalizedExchange = exchange?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
        return (normalizedSymbol, normalizedExchange)
    }
    
    // 저장된 코인 목록을 표준화된 형태로 변환
    private func normalizeCoins(coins: [MarketPrice]) -> [MarketPrice] {
        return coins.map { coin in
            return MarketPrice(
                symbol: coin.symbol.lowercased().trimmingCharacters(in: .whitespaces),
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
    }
}



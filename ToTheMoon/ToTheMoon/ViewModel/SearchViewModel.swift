//
//  SearchViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import Foundation
import RxSwift
import RxCocoa

final class SearchViewModel {
    private let getMarketPricesUseCase: GetMarketPricesUseCase
    private let manageFavoritesUseCase: ManageFavoritesUseCaseProtocol
    private let savedCoinsRelay = BehaviorRelay<Set<String>>(value: Set())
    private let disposeBag = DisposeBag()
    private let symbolFormatter = SymbolFormatter()
    
    private let filteredSearchResultsRelay = BehaviorRelay<[MarketPrice]>(value: [])
    private let recentSearchesRelay = BehaviorRelay<[(String, String, String)]>(value: [])
    private var allMarketPrices = BehaviorRelay<[MarketPrice]>(value: [])
    
    var filteredSearchResults: Observable<[MarketPrice]> {
        return filteredSearchResultsRelay.asObservable()
    }
    
    var recentSearches: Observable<[(String, String, String)]> {
        return recentSearchesRelay.asObservable()
    }
    
    var combinedSearchResults: Observable<[(MarketPrice, Bool)]> {
        filteredSearchResultsRelay
            .flatMapLatest { results in
                Observable.combineLatest(results.map { marketPrice in
                    self.manageFavoritesUseCase.isCoinSaved(marketPrice.symbol, exchange: marketPrice.exchange)
                        .map { isSaved in (marketPrice, isSaved) }
                })
            }
    }
    
    init(getMarketPricesUseCase: GetMarketPricesUseCase, manageFavoritesUseCase: ManageFavoritesUseCaseProtocol) {
        self.getMarketPricesUseCase = getMarketPricesUseCase
        self.manageFavoritesUseCase = manageFavoritesUseCase
        fetchMarketPrices()
        loadSavedCoins()
    }
    
    private func fetchMarketPrices() {
        getMarketPricesUseCase.execute()
            .subscribe(onSuccess: { [weak self] marketPrices in
                self?.allMarketPrices.accept(marketPrices)
            })
            .disposed(by: disposeBag)
    }
    
    private func loadSavedCoins() {
        manageFavoritesUseCase.fetchFavoriteCoins()
            .map { coins -> Set<String> in
                Set(coins.map { "\($0.symbol)_\($0.exchangename)" })
            }
            .bind(to: savedCoinsRelay)
            .disposed(by: disposeBag)
    }
    
    func search(query: String) {
        if query.isEmpty {
            filteredSearchResultsRelay.accept([])
        } else {
            let filtered = allMarketPrices.value.filter {
                $0.symbol.lowercased().contains(query.lowercased()) ||
                $0.exchange.lowercased().contains(query.lowercased())
            }
            filteredSearchResultsRelay.accept(filtered)
        }
    }
    
    func saveSearchHistory(query: String) {
        guard let firstResult = allMarketPrices.value.first(where: {
            $0.symbol.lowercased().contains(query.lowercased()) ||
            $0.exchange.lowercased().contains(query.lowercased())
        }) else { return }
        
        let normalizedSymbol = symbolFormatter.format(symbol: firstResult.symbol)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: Date())
        
        let newEntry = (normalizedSymbol, firstResult.exchange, formattedDate)
        
        if !recentSearchesRelay.value.contains(where: { $0.0 == newEntry.0 }) {
            var updatedRecentSearches = recentSearchesRelay.value
            updatedRecentSearches.insert(newEntry, at: 0)
            if updatedRecentSearches.count > 10 {
                updatedRecentSearches.removeLast()
            }
            recentSearchesRelay.accept(updatedRecentSearches)
        }
    }
    
    func clearSearchHistory() {
        recentSearchesRelay.accept([])
    }
    
    func toggleFavorite(_ marketPrice: MarketPrice) {
        manageFavoritesUseCase.isCoinSaved(marketPrice.symbol, exchange: marketPrice.exchange)
            .flatMap { isSaved -> Observable<Void> in  // ✅ Observable<Bool>을 flatMap으로 변환
                if isSaved {
                    return self.manageFavoritesUseCase.removeCoin(marketPrice) // ✅ 코어데이터에서 삭제
                } else {
                    return self.manageFavoritesUseCase.saveCoin(marketPrice) // ✅ 코어데이터에 추가
                }
            }
            .ignoreElements() // ✅ Observable<Void>를 Completable로 변환
            .subscribe(onCompleted: { [weak self] in
                self?.reloadSavedCoins() // ✅ 변경 사항 반영
            })
            .disposed(by: disposeBag)
    }
    
    private func reloadSavedCoins() {
        manageFavoritesUseCase.fetchFavoriteCoins()
            .map { coins -> Set<String> in
                Set(coins.map { "\($0.symbol)_\($0.exchangename)" })
            }
            .bind(to: savedCoinsRelay)
            .disposed(by: disposeBag)
    }
}

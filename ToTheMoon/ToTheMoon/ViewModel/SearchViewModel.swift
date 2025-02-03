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
                let savedSet: Set<String> = Set(coins.compactMap { coin in
                    guard let symbol = coin.symbol, let exchange = coin.exchangename else { return nil }
                    return "\(symbol)_\(exchange)"
                })
                return savedSet
            }
            .subscribe(onNext: { [weak self] savedCoins in
                self?.savedCoinsRelay.accept(savedCoins)
            })
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
        let coinKey = "\(marketPrice.symbol)_\(marketPrice.exchange)"

        manageFavoritesUseCase.isCoinSaved(marketPrice.symbol, exchange: marketPrice.exchange)
            .observe(on: MainScheduler.asyncInstance)
            .flatMapLatest { isSaved -> Observable<Void> in
                if isSaved {
                    print("🔴 삭제 요청: \(coinKey)")
                    return self.manageFavoritesUseCase.removeCoin(marketPrice)
                } else {
                    print("🟢 추가 요청: \(coinKey)")
                    return self.manageFavoritesUseCase.saveCoin(marketPrice)
                }
            }
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.loadSavedCoins()
            })
            .disposed(by: disposeBag)
    }
    
    func isCoinSaved(_ symbol: String?, exchange: String?) -> Observable<Bool> {
        guard let symbol = symbol, let exchange = exchange else {
            return Observable.just(false)
        }
        let coinKey = "\(symbol)_\(exchange)"
        return savedCoinsRelay
            .map { savedCoins in savedCoins.contains(coinKey) }
            .observe(on: MainScheduler.instance)
    }
}

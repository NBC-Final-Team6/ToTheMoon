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
    private let recentSearchesRelay = BehaviorRelay<[(String, String)]>(value: [])
    private var allMarketPrices = BehaviorRelay<[MarketPrice]>(value: [])
    
    private let userDefaultsKey = "recentSearches" // UserDefaults 저장 키

    var filteredSearchResults: Observable<[MarketPrice]> {
        return filteredSearchResultsRelay.asObservable()
    }
    
    var recentSearches: Observable<[(String, String)]> {
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
        loadRecentSearches()
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
                Set(coins.map { "\($0.symbol)_\($0.exchange)" })
            }
            .bind(to: savedCoinsRelay)
            .disposed(by: disposeBag)
    }

    /// 앱이 시작될 때 저장된 최근 검색어 불러오기
    private func loadRecentSearches() {
        if let savedSearches = UserDefaults.standard.array(forKey: userDefaultsKey) as? [[String]] {
            let searches = savedSearches.compactMap { entry -> (String, String)? in
                guard entry.count == 2 else { return nil }
                return (entry[0], entry[1]) // (심볼 또는 거래소, 날짜)
            }
            recentSearchesRelay.accept(searches)
        }
    }

    /// 최근 검색어 저장 (UserDefaults에도 저장)
    private func saveRecentSearches() {
        let searchesArray = recentSearchesRelay.value.map { [$0.0, $0.1] } // (String, String) → [[String]]
        UserDefaults.standard.set(searchesArray, forKey: userDefaultsKey)
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
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: Date())

        var newEntry: (String, String)

        // 검색어가 심볼인지 거래소인지 판별 (대소문자 구분 없이 처리)
        if let marketSymbol = allMarketPrices.value.first(where: { $0.symbol.lowercased() == trimmedQuery.lowercased() })?.symbol {
            newEntry = (marketSymbol.uppercased(), formattedDate)
        } else if let marketExchange = allMarketPrices.value.first(where: { $0.exchange.lowercased() == trimmedQuery.lowercased() })?.exchange {
            newEntry = (marketExchange.capitalized, formattedDate)
        } else {
            return
        }

        // 중복 검사 후 저장
        if !recentSearchesRelay.value.contains(where: { $0.0.lowercased() == newEntry.0.lowercased() }) {
            var updatedRecentSearches = recentSearchesRelay.value
            updatedRecentSearches.insert(newEntry, at: 0)

            // 최대 10개까지만 저장
            if updatedRecentSearches.count > 10 {
                updatedRecentSearches.removeLast()
            }

            recentSearchesRelay.accept(updatedRecentSearches)
            saveRecentSearches() // 검색 기록 변경 시 UserDefaults에 저장
        }
    }
    
    /// 검색 기록 지우기 (UserDefaults에서도 삭제)
    func clearSearchHistory() {
        recentSearchesRelay.accept([])
        UserDefaults.standard.removeObject(forKey: userDefaultsKey) // 저장된 검색 기록 삭제
    }

    func toggleFavorite(_ marketPrice: MarketPrice) {
        manageFavoritesUseCase.isCoinSaved(marketPrice.symbol, exchange: marketPrice.exchange)
            .flatMap { isSaved -> Observable<Void> in
                if isSaved {
                    return self.manageFavoritesUseCase.removeCoin(marketPrice)
                } else {
                    return self.manageFavoritesUseCase.saveCoin(marketPrice)
                }
            }
            .ignoreElements()
            .subscribe(onCompleted: { [weak self] in
                self?.reloadSavedCoins()
            })
            .disposed(by: disposeBag)
    }
    
    private func reloadSavedCoins() {
        manageFavoritesUseCase.fetchFavoriteCoins()
            .map { coins -> Set<String> in
                Set(coins.map { "\($0.symbol)_\($0.exchange)" })
            }
            .bind(to: savedCoinsRelay)
            .disposed(by: disposeBag)
    }
}


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
    private let disposeBag = DisposeBag()
    private let symbolFormatter = SymbolFormatter()  // ✅ SymbolFormatter 사용
    
    private let filteredSearchResultsRelay = BehaviorRelay<[MarketPrice]>(value: [])
    private let recentSearchesRelay = BehaviorRelay<[(String, String, String)]>(value: []) // 최근 검색 기록 저장
    private var allMarketPrices = BehaviorRelay<[MarketPrice]>(value: []) // 받아온 전체 데이터 저장
    
    var filteredSearchResults: Observable<[MarketPrice]> {
        return filteredSearchResultsRelay.asObservable()
    }
    
    var recentSearches: Observable<[(String, String, String)]> {
        return recentSearchesRelay.asObservable()
    }
    
    init(getMarketPricesUseCase: GetMarketPricesUseCase) {
        self.getMarketPricesUseCase = getMarketPricesUseCase
        fetchMarketPrices()
    }
    
    private func fetchMarketPrices() {
        getMarketPricesUseCase.execute()
            .subscribe(onSuccess: { [weak self] marketPrices in
                self?.allMarketPrices.accept(marketPrices)
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
        }) else { return } // 검색 결과가 없으면 저장 안함
        
        // ✅ 정규화된 심볼 적용
        let normalizedSymbol = symbolFormatter.format(symbol: firstResult.symbol)
        
        // ✅ 날짜 포맷 적용 (yyyy-MM-dd)
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
}

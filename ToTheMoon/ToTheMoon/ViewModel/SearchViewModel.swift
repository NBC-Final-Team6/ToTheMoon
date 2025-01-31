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
    private let manageFavoritesUseCase: ManageFavoritesUseCaseProtocol  // ✅ Use Case 주입
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
        self.manageFavoritesUseCase = manageFavoritesUseCase  // ✅ FavoritesViewModel 의존성 제거
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

    // ✅ 즐겨찾기 추가 (Use Case를 활용)
    func addToFavorites(_ marketPrice: MarketPrice) {
        manageFavoritesUseCase.saveCoin(marketPrice)
            .subscribe(onNext: {
                print("\(marketPrice.symbol) 저장 완료")
            }, onError: { error in
                print("코인 저장 실패: \(error)")
            })
            .disposed(by: disposeBag)
    }

    // ✅ 저장된 코인인지 확인 (Use Case 활용)
    func isCoinSaved(_ symbol: String) -> Observable<Bool> {
        return manageFavoritesUseCase.isCoinSaved(symbol)
    }
}

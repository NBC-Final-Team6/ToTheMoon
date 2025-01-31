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
    private let savedCoinsSubject = BehaviorSubject<Set<String>>(value: [])
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
    
    private func loadSavedCoins() {
        manageFavoritesUseCase.fetchFavoriteCoins()
            .map { coins in
                Set(coins.map { "\(String(describing: $0.symbol))_\($0.exchangename ?? "")" })  // ✅ "symbol + exchange" 조합 생성
            }
            .subscribe(onNext: { [weak self] savedCoins in
                self?.savedCoinsSubject.onNext(savedCoins)
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
            .observe(on: MainScheduler.asyncInstance) // ✅ 이벤트가 비동기적으로 실행되도록 함
            .flatMapLatest { isSaved -> Observable<Void> in
                if isSaved {
                    print("🔴 삭제 요청: \(coinKey)")
                    return self.manageFavoritesUseCase.removeCoin(marketPrice) // ✅ 삭제 요청
                } else {
                    print("🟢 추가 요청: \(coinKey)")
                    return self.manageFavoritesUseCase.saveCoin(marketPrice) // ✅ 추가 요청
                }
            }
            .subscribe(onNext: { [weak self] in
                var savedCoins = (try? self?.savedCoinsSubject.value()) ?? []
                if savedCoins.contains(coinKey) {
                    savedCoins.remove(coinKey) // ✅ 삭제된 경우 제거
                } else {
                    savedCoins.insert(coinKey) // ✅ 추가된 경우 삽입
                }
                self?.savedCoinsSubject.onNext(savedCoins) // ✅ 상태 업데이트
                
                // ✅ 저장된 코인 목록 다시 불러와서 확인 (디버깅)
                self?.manageFavoritesUseCase.fetchFavoriteCoins()
                    .subscribe(onNext: { savedCoins in
                        print("⭐ 현재 저장된 코인 목록:", savedCoins.map { "\(String(describing: $0.symbol))_\($0.exchangename ?? "")" })
                    })
                    .disposed(by: self!.disposeBag)
            })
            .disposed(by: disposeBag)
    }
    
    /// ✅ "symbol + exchange" 조합으로 개별 코인 저장 여부 확인
    func isCoinSaved(_ symbol: String, exchange: String) -> Observable<Bool> {
        let coinKey = "\(symbol)_\(exchange)"
        return savedCoinsSubject
            .map { $0.contains(coinKey) }
            .distinctUntilChanged()
    }
}

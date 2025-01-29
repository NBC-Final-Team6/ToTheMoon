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
    
    private let filteredSearchesRelay = BehaviorRelay<[(String, String, String)]>(value: [])
    private let recentSearchesRelay = BehaviorRelay<[(String, String, String)]>(value: []) // 최근 검색 기록 저장
    private var allMarketPrices: [(String, String, String)] = [] // 받아온 전체 데이터 저장

    var filteredSearches: Observable<[(String, String, String)]> {
        return filteredSearchesRelay.asObservable()
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
                let currentDate = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let formattedDate = dateFormatter.string(from: currentDate)
                
                let searchData = marketPrices.map { marketPrice -> (String, String, String) in
                    let normalizedSymbol = self?.normalizeSymbol(marketPrice.symbol) ?? marketPrice.symbol
                    return (normalizedSymbol, marketPrice.exchange, formattedDate)
                }

                self?.allMarketPrices = searchData // 전체 데이터 저장 (화면에는 직접 표시하지 않음)
            })
            .disposed(by: disposeBag)
    }
    
    // 검색 수행 로직 (최근 검색 기록 저장 X)
    func search(query: String) {
        if query.isEmpty {
            if recentSearchesRelay.value.isEmpty {
                filteredSearchesRelay.accept([]) // 아무것도 표시하지 않음
            } else {
                filteredSearchesRelay.accept(recentSearchesRelay.value) // 최근 검색 기록 표시
            }
        } else {
            let filtered = allMarketPrices.filter {
                $0.0.lowercased().contains(query.lowercased()) ||
                $0.1.lowercased().contains(query.lowercased())
            }
            filteredSearchesRelay.accept(filtered)
        }
    }
    
    // 엔터 또는 검색 버튼 클릭 시 실행되는 검색 기록 저장 함수
    func saveSearchHistory(query: String) {
        guard let firstResult = allMarketPrices.first(where: {
            $0.0.lowercased().contains(query.lowercased()) ||
            $0.1.lowercased().contains(query.lowercased())
        }) else { return } // 검색 결과가 없으면 저장 안함

        // 중복 체크 후 저장
        if !recentSearchesRelay.value.contains(where: { $0.0 == firstResult.0 }) {
            var updatedRecentSearches = recentSearchesRelay.value
            updatedRecentSearches.insert(firstResult, at: 0) // 최근 검색 기록에 추가
            if updatedRecentSearches.count > 10 { // 최근 검색 최대 10개 유지
                updatedRecentSearches.removeLast()
            }
            recentSearchesRelay.accept(updatedRecentSearches)
        }
    }

    private func normalizeSymbol(_ symbol: String) -> String {
        let separators: [Character] = ["-", "_"]
        let fiatCurrencies: Set<String> = ["KRW", "USDT", "USD", "EUR", "JPY"]

        let uppercasedSymbol = symbol.uppercased()
        let components = uppercasedSymbol.split(whereSeparator: { separators.contains($0) }).map { String($0) }

        for component in components {
            if !fiatCurrencies.contains(component) {
                return component
            }
        }
        
        return uppercasedSymbol
    }
    
    // 검색 기록 초기화
    func clearSearchHistory() {
        recentSearchesRelay.accept([]) // 최근 검색 기록 비우기
        filteredSearchesRelay.accept([]) // 현재 검색 결과도 비우기
    }
}

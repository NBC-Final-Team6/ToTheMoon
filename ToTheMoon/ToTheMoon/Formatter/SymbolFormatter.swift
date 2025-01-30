//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/29/25.
//

import Foundation

final class SymbolFormatter {
    
    /// 심볼을 정리하고 변환된 값을 반환
    func format(symbol: String) -> String {
        let normalizedSymbol = normalizeSymbol(symbol)
        return normalizedSymbol.lowercased()
    }
    
    /// 심볼에서 법정 화폐 및 불필요한 구분자를 제거
    private func normalizeSymbol(_ symbol: String) -> String {
        let separators: [Character] = ["-", "_"]
        let fiatCurrencies: Set<String> = ["KRW"]
        
        let uppercasedSymbol = symbol.uppercased()
        let components = uppercasedSymbol.split(whereSeparator: { separators.contains($0) }).map { String($0) }
        
        for component in components {
            if !fiatCurrencies.contains(component) {
                return component
            }
        }
        
        return uppercasedSymbol
    }
}

//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/29/25.
//

import Foundation

final class SymbolFormatter {
    private let normalizedSymbolMap: [String: String] = [
        "BTC": "bitcoin",
        "ETH": "ethereum",
        "ETC": "ethereum-classic",
        "XRP": "ripple",
        "BCH": "bitcoin-cash",
        "QTUM": "qtum",
        "BTG": "bitcoin-gold",
        "EOS": "eos",
        "ICX": "icon",
        "TRX": "tron",
        "ELF": "aelf",
        "KNC": "kyber-network",
        "GLM": "golem",
        "ZIL": "zilliqa",
        "WAXP": "wax",
        "POWR": "power-ledger",
        "LRC": "loopring",
        "STEEM": "steem",
        "ZRX": "0x",
        "SNT": "status",
        "ADA": "cardano",
        "CTXC": "cortex",
        "BAT": "basic-attention-token",
        "THETA": "theta-token",
        "LOOM": "loom-network",
        "CVC": "civic",
        "WAVES": "waves",
        "LINK": "chainlink",
        "ENJ": "enjincoin",
        "VET": "vechain",
        "MTL": "metal",
        "IOST": "iost",
        "AMO": "amo",
        "BSV": "bitcoin-sv",
        "ORBS": "orbs",
        "TFUEL": "theta-fuel",
        "VALOR": "valor-token",
        "ANKR": "ankr",
        "MIX": "mixmarvel",
        "CRO": "crypto-com-chain",
        "FX": "function-x",
        "CHR": "chromia",
        "MBL": "moviebloc",
        "FCT2": "firmachain",
        "WOM": "wom-token",
        "BOA": "bosagora",
        "MEV": "meverse",
        "SXP": "swipe",
        "COS": "contentos",
        "EL": "elysia",
        "HIVE": "hive",
        "XPR": "proton",
        "FIT": "fit-token",
        "EGG": "nestree",
        "BORA": "bora",
        "ARPA": "arpa-chain",
        "CTC": "creditcoin",
        "APM": "apm-coin",
        "CKB": "nervos-network",
        "AERGO": "aergo",
        "EVZ": "electric-vehicle-zone",
        "QTCON": "quiztok",
        "UNI": "uniswap",
        "YFI": "yearn-finance",
        "UMA": "uma",
        "AAVE": "aave",
        "COMP": "compound",
        "BAL": "balancer",
        "RSR": "reserve-rights-token",
        "NMR": "numeraire",
        "RLC": "iexec-rlc",
        "UOS": "ultra",
        "SAND": "the-sandbox",
        "STPT": "stp-network",
        "BEL": "bella-protocol",
        "OBSR": "observer",
        "POLA": "polkadot",
        "ADP": "adappter-token"
        // 나머지 매핑 추가 가능
    ]
    
    /// 심볼을 정리하고 변환된 값을 반환
    func format(symbol: String) -> String {
        let normalizedSymbol = normalizeSymbol(symbol)
        return normalizedSymbolMap[normalizedSymbol] ?? normalizedSymbol
    }
    
    /// 심볼에서 법정 화폐 및 불필요한 구분자를 제거
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
}

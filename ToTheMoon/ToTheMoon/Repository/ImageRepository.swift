//
//  ImageRepository.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/29/25.
//

import UIKit

final class ImageRepository {
    // 코인 심볼 -> 번들 이미지 매핑
    private static let defaultSymbolImages: [String: String] = [
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
    
    // 기본 심볼 이미지 가져오기
    static func getImage(for symbol: String) -> UIImage? {
        let normalizedSymbol = symbol.uppercased()
        if let imageName = defaultSymbolImages[normalizedSymbol] {
            return UIImage(named: imageName) // Assets에서 이미지 로드
        }
        return UIImage(named: "bitcoin") // 기본 이미지 반환 (없을 경우)
    }
}

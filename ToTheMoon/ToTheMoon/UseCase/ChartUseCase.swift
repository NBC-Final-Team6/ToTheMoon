//
//  ChartUseCase.swift
//  ToTheMoon
//
//  Created by 강민성 on 2/12/25.
//
import RxSwift
import DGCharts
import Foundation
// 캔들 데이터를 가져오는 공통 프로토콜
protocol CandleServiceType {
    func fetchCandles(symbol: String, interval: CandleInterval, count: Int) -> Single<[Candle]>
}
// ChartUseCase는 선택된 코인에 대한 캔들 데이터를 가져와서 차트에 필요한 데이터를 생성합니다.
// 또한, SymbolService를 이용하여 코인 설명 데이터를 가져옵니다.
final class ChartUseCase {
    
    private let exchange: Exchange?
    private let services: [Exchange: CandleServiceType]
    private let symbolService: SymbolService
    
    init(exchange: Exchange?) {
        self.exchange = exchange
        // 서비스 클래스는 아래 extension에서 CandleServiceType 준수를 선언합니다.
        self.services = [
            .bithumb: BithumbService() as CandleServiceType,
            .coinone: CoinOneService() as CandleServiceType,
            .korbit:  KorbitService() as CandleServiceType,
            .upbit:   UpbitService() as CandleServiceType
        ]
        self.symbolService = SymbolService()
    }
    
    // 지정된 코인과 캔들 간격에 대해 차트 데이터를 생성합니다.
    func fetchChartData(for coin: MarketPrice, interval: CandleInterval) -> Observable<(dates: [String],
                                                                                           entries: [CandleChartDataEntry],
                                                                                           highest: String,
                                                                                           lowest: String,
                                                                                           xAxisFormatter: AxisValueFormatter)> {
        guard let exchange = exchange, let service = services[exchange] else {
            let emptyFormatter = IndexAxisValueFormatter(values: [])
            return Observable.just(([], [], "0", "0", emptyFormatter))
        }
        
        return service.fetchCandles(symbol: coin.symbol, interval: interval, count: 50)
            .asObservable()
            .map { candles in
                // 캔들 응답의 타임스탬프를 날짜 문자열로 변환
                let timestamps = candles.map { TimeInterval($0.timestamp / 1000) }
                let formatter = DateFormatter()
                let dateFormat: String
                switch interval {
                case .minute:
                    dateFormat = "HH:mm"
                case .hour:
                    dateFormat = "HH시"
                case .day:
                    dateFormat = "M월 d일"
                case .week:
                    dateFormat = "M월 W주"
                case .month:
                    dateFormat = "YYYY년 M월"
                }
                formatter.dateFormat = dateFormat
                let dates = timestamps
                    .map { formatter.string(from: Date(timeIntervalSince1970: $0)) }
                    .reversed()
                let datesArray = Array(dates)
                
                let entries = candles.enumerated().map { index, candle in
                    CandleChartDataEntry(x: Double(index),
                                           shadowH: candle.high,
                                           shadowL: candle.low,
                                           open: candle.open,
                                           close: candle.close)
                }
                
                let highest = candles.max(by: { $0.high < $1.high })?.high ?? 0
                let lowest  = candles.min(by: { $0.low < $1.low })?.low ?? 0
                let xAxisFormatter = IndexAxisValueFormatter(values: datesArray)
                
                return (datesArray, entries, "\(highest)", "\(lowest)", xAxisFormatter)
            }
    }
    
    // 지정된 코인 심볼 목록에 대해 코인 설명 정보를 가져옵니다.
    func fetchCoinDescriptions(for symbols: [String]) -> Single<[String: String]> {
        return symbolService.fetchCoinIDMap()
            .flatMap { _ -> Single<[String: String]> in
                let coinInfoRequests = symbols.map { symbol in
                    self.fetchCoinDescription(symbol: self.convertToCoinGeckoID(symbol),
                                              originalSymbol: symbol)
                        .map { (symbol.uppercased(), $0.description.ko) }
                }
                return Single.zip(coinInfoRequests)
                    .map { Dictionary(uniqueKeysWithValues: $0) }
            }
    }
    
    // 심볼을 코인게코 ID로 변환 (캐시된 매핑 사용)
    private func convertToCoinGeckoID(_ symbol: String) -> String {
        return symbolService.symbolToIDMap[symbol.lowercased()] ?? symbol
    }
    
    private func fetchCoinDescription(symbol: String, originalSymbol: String) -> Single<SymbolData> {
        return symbolService.fetchCoinDataAll(coinSymbol: symbol)
            .catch { _ in
                self.symbolService.fetchCoinDataAll(coinSymbol: originalSymbol)
            }
    }
}
// MARK: - CandleServiceType Conformance
extension BithumbService: CandleServiceType {}
extension CoinOneService: CandleServiceType {}
extension KorbitService: CandleServiceType {}
extension UpbitService: CandleServiceType {}




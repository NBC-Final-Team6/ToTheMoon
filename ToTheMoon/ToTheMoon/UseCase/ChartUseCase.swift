//
//  ChartUseCase.swift
//  ToTheMoon
//
//  Created by 강민성 on 2/12/25.
//

import RxSwift
import DGCharts
import Foundation

protocol CandleServiceType {
    func fetchCandles(symbol: String, interval: CandleInterval, count: Int) -> Single<[Candle]>
}

final class ChartUseCase {
    
    private let exchange: Exchange?
    private let services: [Exchange: CandleServiceType]
    private let webSocketServices: [Exchange: WebSocketServiceProtocol]
    
    init(exchange: Exchange?) {
        self.exchange = exchange
        self.services = [
            .bithumb: BithumbService() as CandleServiceType,
            .coinone: CoinOneService() as CandleServiceType,
            .korbit:  KorbitService() as CandleServiceType,
            .upbit:   UpbitService() as CandleServiceType
        ]
        
        self.webSocketServices = [
            .bithumb: BithumbWebSocketService(),
            .coinone: CoinoneWebSocketService(),
            .korbit: KorbitWebSocketService(),
            .upbit: UpbitWebSocketService()
        ]
        
    }
    
    // 지정된 코인과 캔들 간격에 대해 차트 데이터를 생성합니다.
    func fetchChartData(for coin: MarketPrice, interval: CandleInterval) -> Observable<(dates: [String], entries: [CandleChartDataEntry], highest: String, lowest: String, xAxisFormatter: AxisValueFormatter)> {
        guard let exchange = exchange, let service = services[exchange] else {
            return Observable.just(([], [], "0", "0", IndexAxisValueFormatter(values: [])))
        }
        
        return service.fetchCandles(symbol: coin.symbol, interval: interval, count: 50)
            .asObservable()
            .map { candles in
                let timestamps = candles.map { TimeInterval($0.timestamp / 1000) }
                let formatter = DateFormatter()
                formatter.dateFormat = interval == .minute ? "HH:mm" : "M월 d일"
                let dates = timestamps.map { formatter.string(from: Date(timeIntervalSince1970: $0)) }.reversed()
                
                let entries = candles.enumerated().map { index, candle in
                    
                    CandleChartDataEntry(
                        x: Double(index),
                        shadowH: candle.high,
                        shadowL: candle.low,
                        open: candle.open,
                        close: candle.close
                    )
                }
                
                let highest = candles.max(by: { $0.high < $1.high })?.high ?? 0
                let lowest = candles.min(by: { $0.low < $1.low })?.low ?? 0
                
                return (Array(dates), entries, "\(highest)", "\(lowest)", IndexAxisValueFormatter(values: Array(dates)))
            }
    }
    
    // ✅ 실시간 캔들 데이터 업데이트 (WebSocket)
    func subscribeToRealTimeCandleData(for coin: MarketPrice) -> Observable<MarketPrice> {
        guard let exchange = exchange, let webSocketService = webSocketServices[exchange] else {
            return Observable.just(coin) // 기본값 반환
        }
        
        return webSocketService.fetchKrwTicker(for: [coin.symbol])
            .compactMap { prices in
                let firstPrice = prices.first
                print("✅ WebSocket 실시간 데이터: \(String(describing: firstPrice))") // 디버깅 로그 추가
                return firstPrice
            }
            .observe(on: MainScheduler.instance)
    }
}

// MARK: - CandleServiceType Conformance

extension BithumbService: CandleServiceType {}
extension CoinOneService: CandleServiceType {}
extension KorbitService: CandleServiceType {}
extension UpbitService: CandleServiceType {}

//
//  ChartViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import RxSwift
import RxCocoa
import DGCharts
import UIKit

final class ChartViewModel {

    // MARK: - Inputs
    let symbol: String // 코인 심볼
    let exchange: Exchange // 거래소 정보
    let candleInterval: BehaviorSubject<CandleInterval> = BehaviorSubject(value: .day) // 차트 시간 간격

    // MARK: - Outputs
    let chartData: PublishSubject<([String], [CandleChartDataEntry])> = PublishSubject() // 차트 데이터
    let currentPrice: BehaviorSubject<String> = BehaviorSubject(value: "0") // 현재 가격
    let priceTrend: BehaviorSubject<String> = BehaviorSubject(value: "") // 상승/하락 텍스트
    let priceTrendColor: BehaviorSubject<UIColor> = BehaviorSubject(value: .black) // 상승/하락 색상
    let changeRate: BehaviorSubject<String> = BehaviorSubject(value: "0.0%") // 변동률 (퍼센티지)
    let highestPrice: BehaviorSubject<String> = BehaviorSubject(value: "0") // 최고가
    let lowestPrice: BehaviorSubject<String> = BehaviorSubject(value: "0") // 최저가
    let coinInfo: BehaviorSubject<String> = BehaviorSubject(value: "") // 디지털 자산 소개

    // MARK: - Dependencies
    private let disposeBag = DisposeBag()
    private let service: BithumbService

    // MARK: - Initializer
    init(symbol: String, exchange: Exchange) {
        self.symbol = symbol
        self.exchange = exchange
        self.service = BithumbService()
        bindInputs()
    }

    // MARK: - Methods
    // 사용자 입력에 따라 데이터를 가져오는 바인딩 설정
    private func bindInputs() {
        candleInterval
            .flatMapLatest { interval -> Observable<[Candle]> in
                return self.service.fetchCandles(symbol: self.symbol, interval: interval, count: 50)
                    .asObservable()
            }
            .subscribe(onNext: { candles in
                let dates = candles.map {
                    DateFormatter.localizedString(from: Date(timeIntervalSince1970: TimeInterval($0.timestamp / 1000)), dateStyle: .short, timeStyle: .none)
                }
                let entries = candles.enumerated().map { index, candle in
                    CandleChartDataEntry(x: Double(index), shadowH: candle.high, shadowL: candle.low, open: candle.open, close: candle.close)
                }
                self.chartData.onNext((dates, entries))
            }, onError: { error in
                print("Error fetching candles: \(error)")
            })
            .disposed(by: disposeBag)
    }
    
    // 데이터를 주기적으로 가져오는 메서드
    func fetchMarketData() {
        Observable<Int>.interval(.seconds(5), scheduler: MainScheduler.instance) // 실시간 업데이트
            .flatMapLatest { _ in
                self.service.fetchMarketPrices().asObservable()
            }
            .subscribe(onNext: { prices in
                if let price = prices.first(where: { $0.symbol == "KRW-\(self.symbol)" }) {
                    // 현재 가격
                    self.currentPrice.onNext("KRW \(price.price)")

                    // 변동률
                    let changeRateValue = (price.changeRate * 100).rounded(toPlaces: 2)
                    self.changeRate.onNext("\(changeRateValue)%")

                    // 상승/하락 상태 및 색상 설정
                    let trendText: String
                    if price.change == "RISE" {
                        trendText = "상승"
                        self.priceTrendColor.onNext(.green)
                    } else if price.change == "FALL" {
                        trendText = "하락"
                        self.priceTrendColor.onNext(.red)
                    } else {
                        trendText = "변동 없음"
                        self.priceTrendColor.onNext(.gray)
                    }
                    self.priceTrend.onNext(trendText)

                    // 최고가, 최저가
                    self.highestPrice.onNext("KRW \(price.highPrice)")
                    self.lowestPrice.onNext("KRW \(price.lowPrice)")
                }
            }, onError: { error in
                print("Error fetching market data: \(error)")
            })
            .disposed(by: disposeBag)
    }
    
    // 코인의 디지털 자산 소개 데이터를 가져오는 메서드
    func fetchCoinInfo() {
        let symbolService = SymbolService()
        symbolService.fetchCoinData(coinSymbol: self.symbol)
            .asObservable()
            .subscribe(onNext: { coin in
                self.coinInfo.onNext(coin.description.ko)
            }, onError: { error in
                print("Error fetching coin info: \(error)")
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Double Extension
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

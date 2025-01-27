//
//  ChartViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import RxSwift
import RxCocoa
import UIKit
import DGCharts

final class ChartViewModel {

    // MARK: - Inputs
    let exchange: Exchange? // 선택된 거래소 정보 (optional, 모든 거래소 데이터를 가져올 수도 있음)
    let candleInterval: BehaviorSubject<CandleInterval> = BehaviorSubject(value: .day) // 차트 시간 간격

    // MARK: - Outputs
    let chartData: PublishSubject<([String], [CandleChartDataEntry])> = PublishSubject() // 차트 데이터
    let highestPrice: BehaviorSubject<String> = BehaviorSubject(value: "0") // 최고가
    let lowestPrice: BehaviorSubject<String> = BehaviorSubject(value: "0") // 최저가
    let coinInfo: BehaviorSubject<String> = BehaviorSubject(value: "") // 디지털 자산 소개

    // MARK: - Dependencies
    private let disposeBag = DisposeBag()
    private let services: [Exchange: Any] // 각 거래소의 서비스 인스턴스

    // MARK: - Initializer
    init(exchange: Exchange?) {
        self.exchange = exchange

        self.services = [
            .bithumb: BithumbService(),
            .coinone: CoinOneService(),
            .korbit: KorbitService(),
            .upbit: UpbitService()
        ]

        bindInputs()
    }

    // MARK: - Methods
    private func bindInputs() {
        candleInterval
            .flatMapLatest { interval -> Observable<[Candle]> in
                if let exchange = self.exchange {
                    // 특정 거래소의 데이터를 가져옴
                    return self.fetchCandles(from: exchange, interval: interval, count: 50)
                } else {
                    // 모든 거래소의 데이터를 병합
                    return Observable.zip(self.services.keys.map { self.fetchCandles(from: $0, interval: interval, count: 50) })
                        .map { $0.flatMap { $0 } } // 데이터를 병합
                }
            }
            .subscribe(onNext: { candles in
                let dates = candles.map {
                    DateFormatter.localizedString(from: Date(timeIntervalSince1970: TimeInterval($0.timestamp / 1000)), dateStyle: .short, timeStyle: .none)
                }
                let entries = candles.enumerated().map { index, candle in
                    CandleChartDataEntry(x: Double(index), shadowH: candle.high, shadowL: candle.low, open: candle.open, close: candle.close)
                }
                self.chartData.onNext((dates, entries))

                // 최고가와 최저가 업데이트
                if let highest = candles.max(by: { $0.high < $1.high })?.high,
                   let lowest = candles.min(by: { $0.low < $1.low })?.low {
                    self.highestPrice.onNext("KRW \(highest)")
                    self.lowestPrice.onNext("KRW \(lowest)")
                }
            }, onError: { error in
                print("Error fetching candles: \(error)")
            })
            .disposed(by: disposeBag)
    }

    func fetchCoinInfo() {
        let symbolService = SymbolService()
        symbolService.fetchCoinData(coinSymbol: "") // 코인심볼은 뷰컨트롤러에서 전달받아 직접 처리
            .asObservable()
            .subscribe(onNext: { coin in
                self.coinInfo.onNext(coin.description.ko)
            }, onError: { error in
                print("Error fetching coin info: \(error)")
            })
            .disposed(by: disposeBag)
    }

    private func fetchCandles(from exchange: Exchange, interval: CandleInterval, count: Int) -> Observable<[Candle]> {
        guard let service = services[exchange] else {
            return Observable.just([])
        }

        switch service {
        case let service as BithumbService:
            return service.fetchCandles(symbol: "", interval: interval, count: count).asObservable() // 심볼은 뷰컨트롤러에서 전달
        case let service as UpbitService:
            return service.fetchCandles(symbol: "", interval: interval, count: count).asObservable()
        case let service as CoinOneService:
            return service.fetchCandles(symbol: "", interval: interval, count: count).asObservable()
        case let service as KorbitService:
            return service.fetchCandles(symbol: "", interval: interval, count: count).asObservable()
        default:
            return Observable.just([])
        }
    }
}

// MARK: - Double Extension
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

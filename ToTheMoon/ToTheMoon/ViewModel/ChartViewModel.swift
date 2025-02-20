//
//  ChartViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//


import RxSwift
import RxCocoa
import DGCharts
import Foundation
import UIKit

final class ChartViewModel {
    
    // MARK: - Input & Output 구조체
    struct Input {
        let selectedCoins: BehaviorRelay<[MarketPrice]>
        let candleInterval: BehaviorRelay<CandleInterval>
    }
    
    struct Output {
        let chartData: Driver<(dates: [String], entries: [CandleChartDataEntry], highest: String, lowest: String, xAxisFormatter: AxisValueFormatter)>
        let currentPrices: Driver<[String: String]>
        let priceChangeRates: Driver<[String: String]>
        let coinInfo: Driver<[String: String]>
        let highestPrice: Driver<String>
        let lowestPrice: Driver<String>
        let image: Driver<(String, UIImage?)>
    }
    
    let input: Input
    let output: Output
    
    // MARK: - Private Properties
    private let disposeBag = DisposeBag()
    private let chartUseCase: ChartUseCase
    private let manageFavoritesUseCase: ManageFavoritesUseCase
    
    // 내부 Relay
    private let chartDataRelay = BehaviorRelay<(dates: [String], entries: [CandleChartDataEntry], highest: String, lowest: String, xAxisFormatter: AxisValueFormatter)>(
        value: ([], [], "0", "0", IndexAxisValueFormatter(values: []))
    )
    private let currentPricesRelay = BehaviorRelay<[String: String]>(value: [:])
    private let priceChangeRatesRelay = BehaviorRelay<[String: String]>(value: [:])
    private let coinInfoRelay = BehaviorRelay<[String: String]>(value: [:])
    private let highestPriceRelay = BehaviorRelay<String>(value: "0")
    private let lowestPriceRelay = BehaviorRelay<String>(value: "0")
    private let imageSubject = PublishSubject<(String, UIImage?)>()
    
    init(exchange: Exchange?, selectedCoins: [MarketPrice], manageFavoritesUseCase: ManageFavoritesUseCase = ManageFavoritesUseCase()) {
        let selectedCoinsRelay = BehaviorRelay<[MarketPrice]>(value: selectedCoins)
        let candleIntervalRelay = BehaviorRelay<CandleInterval>(value: .day)
        self.input = Input(selectedCoins: selectedCoinsRelay, candleInterval: candleIntervalRelay)
        
        self.chartUseCase = ChartUseCase(exchange: exchange)
        self.manageFavoritesUseCase = manageFavoritesUseCase
        
        self.output = Output(
            chartData: chartDataRelay.asDriver(onErrorDriveWith: .empty()),
            currentPrices: currentPricesRelay.asDriver(),
            priceChangeRates: priceChangeRatesRelay.asDriver(),
            coinInfo: coinInfoRelay.asDriver(),
            highestPrice: highestPriceRelay.asDriver(),
            lowestPrice: lowestPriceRelay.asDriver(),
            image: imageSubject.asDriver(onErrorDriveWith: .empty())
        )
        
        setupBindings()
    }
    
    private func setupBindings() {
        input.selectedCoins.asObservable()
            .subscribe(onNext: { [weak self] coins in
                guard let self = self, let firstCoin = coins.first else { return }
                self.fetchAndUpdateChartData(for: firstCoin)
                self.subscribeToRealTimeUpdates(for: firstCoin) // ✅ 여기 수정
            })
            .disposed(by: disposeBag)
        
        input.candleInterval
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, let firstCoin = self.input.selectedCoins.value.first else { return }
                print("✅ 차트 업데이트 - 새로운 시간 간격 적용")
                self.fetchAndUpdateChartData(for: firstCoin)
            })
            .disposed(by: disposeBag)
    }
    
    // ✅ **차트 데이터 가져오기 (REST API)**
    private func fetchAndUpdateChartData(for coin: MarketPrice) {
        chartUseCase.fetchChartData(for: coin, interval: input.candleInterval.value)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] newData in
                guard let self = self else { return }
                
                self.chartDataRelay.accept(newData)
                self.highestPriceRelay.accept(newData.highest) // ✅ 최고가 업데이트
                self.lowestPriceRelay.accept(newData.lowest)   // ✅ 최저가 업데이트
                
            }, onError: { error in
                print("❌ 차트 데이터 가져오기 실패: \(error)")
            })
            .disposed(by: disposeBag)
    }
    
    // ✅ **실시간 캔들 업데이트 (WebSocket)**
    func subscribeToRealTimeUpdates(for coin: MarketPrice) {
        chartUseCase.subscribeToRealTimeCandleData(for: coin)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] livePrice in
                guard let self = self else { return }

                print("✅ 실시간 업데이트: \(coin.symbol) - \(livePrice.price)")
                
                // ✅ 실시간 가격 및 변동률 업데이트
                var updatedPrices = self.currentPricesRelay.value
                updatedPrices[coin.symbol] = "\(livePrice.price)"
                self.currentPricesRelay.accept(updatedPrices)

                var updatedRates = self.priceChangeRatesRelay.value
                updatedRates[coin.symbol] = "\(String(format: "%.2f", livePrice.changeRate))%"
                self.priceChangeRatesRelay.accept(updatedRates)

                let currentTime = Date()
                let calendar = Calendar.current
                
                let formatter = DateFormatter()
                switch self.input.candleInterval.value {
                case .minute:
                    formatter.dateFormat = "HH:mm"
                case .day:
                    formatter.dateFormat = "yyyy-MM-dd"
                case .week:
                    formatter.dateFormat = "yyyy-MM-dd"
                case .month:
                    formatter.dateFormat = "yyyy년 MM월"
                default:
                    formatter.dateFormat = "yyyy-MM-dd"
                }

                let newDateLabel = formatter.string(from: currentTime)

                let timestamps = self.chartDataRelay.value.dates.compactMap {
                    formatter.date(from: $0)
                }
                
                let lastCandleTime = timestamps.last ?? Date.distantPast
                
                var updatedEntries = self.chartDataRelay.value.entries

                var shouldCreateNewCandle = false
                switch self.input.candleInterval.value {
                case .minute:
                    shouldCreateNewCandle = calendar.component(.minute, from: currentTime) != calendar.component(.minute, from: lastCandleTime)
                case .day:
                    shouldCreateNewCandle = !calendar.isDate(currentTime, inSameDayAs: lastCandleTime)
                case .week:
                    shouldCreateNewCandle = calendar.component(.weekOfYear, from: currentTime) != calendar.component(.weekOfYear, from: lastCandleTime)
                case .month:
                    shouldCreateNewCandle = calendar.component(.month, from: currentTime) != calendar.component(.month, from: lastCandleTime)
                @unknown default:
                    shouldCreateNewCandle = false
                }

                if shouldCreateNewCandle {
                    print("✅ 새로운 캔들 생성됨: \(newDateLabel)")
                    let newCandle = CandleChartDataEntry(
                        x: Double(updatedEntries.count),
                        shadowH: Double(livePrice.price),
                        shadowL: Double(livePrice.price),
                        open: Double(livePrice.price),
                        close: Double(livePrice.price)
                    )
                    updatedEntries.append(newCandle)

                    self.chartDataRelay.accept((
                        self.chartDataRelay.value.dates + [newDateLabel],
                        updatedEntries,
                        self.highestPriceRelay.value,
                        self.lowestPriceRelay.value,
                        IndexAxisValueFormatter(values: self.chartDataRelay.value.dates + [newDateLabel])
                    ))

                } else {
                    // ✅ 기존 캔들 업데이트 (형식 일치 유지)
                    if var lastEntry = updatedEntries.last {
                        lastEntry = CandleChartDataEntry(
                            x: lastEntry.x,
                            shadowH: max(lastEntry.high, livePrice.price),
                            shadowL: min(lastEntry.low, livePrice.price),
                            open: lastEntry.open,
                            close: livePrice.price
                        )
                        updatedEntries[updatedEntries.count - 1] = lastEntry
                    }

                    self.chartDataRelay.accept((
                        self.chartDataRelay.value.dates,
                        updatedEntries,
                        self.highestPriceRelay.value,
                        self.lowestPriceRelay.value,
                        IndexAxisValueFormatter(values: self.chartDataRelay.value.dates)
                    ))
                }

            }, onError: { error in
                print("❌ 실시간 데이터 업데이트 실패: \(error)")
            })
            .disposed(by: disposeBag)
    }
    
    // 즐겨찾기 관련 기능 (Core Data 연동)
    func toggleFavorite(for coin: MarketPrice) {
        manageFavoritesUseCase.toggleFavorite(coin)
            .subscribe(onError: { error in
                print("❌ 즐겨찾기 토글 실패: \(error)")
            }, onCompleted: {
                print("✅ 즐겨찾기 토글 완료: \(coin.symbol)")
                NotificationCenter.default.post(name: NSNotification.Name("FavoriteListUpdated"), object: nil)
            })
            .disposed(by: disposeBag)
    }

    func isFavorite(_ coin: MarketPrice) -> Observable<Bool> {
           return manageFavoritesUseCase.isCoinSaved(coin.symbol, exchange: coin.exchange)
               .distinctUntilChanged()
       }
}

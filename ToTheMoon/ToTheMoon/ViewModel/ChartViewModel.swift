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
        let coinDetails: Driver<(totalSupply: String, circulatingSupply: String, marketCap: String)>
    }
    
    let input: Input
    let output: Output
    
    // MARK: - Private Properties
    private let disposeBag = DisposeBag()
    private let chartUseCase: ChartUseCase
    private let manageFavoritesUseCase: ManageFavoritesUseCase
    private var descriptionDisposeBag = DisposeBag()
    
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
    private let coinDetailsRelay = BehaviorRelay<(totalSupply: String, circulatingSupply: String, marketCap: String)>(value: ("0", "0", "0"))
    
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
            image: imageSubject.asDriver(onErrorDriveWith: .empty()),
            coinDetails: coinDetailsRelay.asDriver()
        )
        
        setupBindings()
    }
    
    // ✅ 선택된 코인에 대해서만 설명 데이터 불러오기
    private func setupBindings() {
        input.selectedCoins.asObservable()
            .subscribe(onNext: { [weak self] coins in
                guard let self = self, let firstCoin = coins.first else { return }
                self.fetchAndUpdateChartData(for: firstCoin)
                self.subscribeToRealTimeUpdates(for: firstCoin)
            })
            .disposed(by: disposeBag)
        
        input.candleInterval
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, let firstCoin = self.input.selectedCoins.value.first else { return }
                // 차트 데이터만 초기화합니다. (설명 데이터 등은 유지)
                self.chartDataRelay.accept(([], [], "0", "0", IndexAxisValueFormatter(values: [])))
                self.fetchAndUpdateChartData(for: firstCoin)
                self.subscribeToRealTimeUpdates(for: firstCoin)
            })
            .disposed(by: disposeBag)
    }
    
    // ✅ 숫자에 콤마 추가 (100,000,000)
    private func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    // ✅ 시가총액 한국식 단위로 변환 (1억, 1조 등)
    private func formatMarketCap(_ value: Double) -> String {
        let trillion = 1_000_000_000_000.0
        let billion = 100_000_000.0
        let million = 1_000_000.0
        
        if value >= trillion {
            return "\(String(format: "%.2f", value / trillion))조"
        } else if value >= billion {
            return "\(String(format: "%.2f", value / billion))억"
        } else if value >= million {
            return "\(String(format: "%.2f", value / million))백만"
        } else {
            return formatNumber(value)
        }
    }
    
    func fetchAndUpdateAllCoinData(for symbol: String) -> Observable<Void> {
        return Observable.zip(
            chartUseCase.fetchCoinDescriptionByImageRepository(for: symbol),
            chartUseCase.fetchCoinFullDataByImageRepository(for: symbol)
        )
        .observe(on: MainScheduler.instance)
        .do(onNext: { [weak self] description, data in
            self?.coinInfoRelay.accept([symbol.uppercased(): description])
            let totalSupply = self?.formatNumber(data.market_data?.max_supply ?? 0.0) ?? "0"
            let circulatingSupply = self?.formatNumber(data.market_data?.circulating_supply ?? 0.0) ?? "0"
            let marketCapValue = data.market_data?.market_cap?["krw"] ?? 0.0
            let marketCap = self?.formatMarketCap(marketCapValue) ?? "0"
            self?.coinDetailsRelay.accept((totalSupply, circulatingSupply, marketCap))
        })
        .map { _ in }
    }
    
    // 코인 설명 데이터 가져오기
    func fetchAndUpdateCoinDescription(for symbol: String) {
        descriptionDisposeBag = DisposeBag() // ✅ 기존 요청 취소
        coinInfoRelay.accept([symbol.uppercased(): "📡 설명 데이터를 불러오는 중입니다..."])

        chartUseCase.fetchCoinDescriptionByImageRepository(for: symbol)
            .observe(on: MainScheduler.instance)
            .retryWhen { (errorObservable: Observable<Error>) in
                errorObservable.enumerated().flatMap { (attempt, error) -> Observable<Int> in
                    let delay = pow(2.0, Double(attempt)) // 2, 4, 8초 대기
                    print("⚡ 재요청 대기: \(delay)초 후 재시도")
                    return Observable<Int>.timer(RxTimeInterval.seconds(Int(delay)), scheduler: MainScheduler.instance)
                }
            }
            .subscribe(onNext: { [weak self] description in
                self?.coinInfoRelay.accept([symbol.uppercased(): description])
                print("✅ [INFO] 설명 데이터 업데이트 완료: \(symbol)")
            }, onError: { error in
                print("❌ [ERROR] 설명 데이터 업데이트 실패: \(error.localizedDescription)")
            })
            .disposed(by: descriptionDisposeBag)
    }
    
    // 차트 데이터 가져오기 (REST API)
    private func fetchAndUpdateChartData(for coin: MarketPrice) {
        chartUseCase.fetchChartData(for: coin, interval: input.candleInterval.value)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] newData in
                guard let self = self else { return }

                // ✅ 기존 데이터와 새로운 데이터 병합
                let existingDates = self.chartDataRelay.value.dates
                let existingEntries = self.chartDataRelay.value.entries

                let mergedDates = existingDates + newData.dates.filter { !existingDates.contains($0) }
                let mergedEntries = existingEntries + newData.entries

                self.chartDataRelay.accept((
                    mergedDates,
                    mergedEntries,
                    newData.highest,
                    newData.lowest,
                    IndexAxisValueFormatter(values: mergedDates)
                ))

                self.highestPriceRelay.accept(newData.highest)
                self.lowestPriceRelay.accept(newData.lowest)
            })
            .disposed(by: disposeBag)
    }
    
    // 실시간 캔들 업데이트 (WebSocket)
    func subscribeToRealTimeUpdates(for coin: MarketPrice) {
        chartUseCase.subscribeToRealTimeCandleData(for: coin)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] livePrice in
                guard let self = self else { return }
                
                print("✅ 실시간 업데이트: \(coin.symbol) - \(livePrice.price)")
                
                // 실시간 가격 및 변동률 업데이트
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
                
                var updatedEntries = self.chartDataRelay.value.entries
                var updatedDates = self.chartDataRelay.value.dates
                
                var shouldCreateNewCandle = false
                if let lastDateString = updatedDates.last,
                   let lastCandleDate = formatter.date(from: lastDateString) {
                    switch self.input.candleInterval.value {
                    case .minute:
                        shouldCreateNewCandle = calendar.component(.minute, from: currentTime) != calendar.component(.minute, from: lastCandleDate)
                    case .day:
                        shouldCreateNewCandle = !calendar.isDate(currentTime, inSameDayAs: lastCandleDate)
                    case .week:
                        shouldCreateNewCandle = calendar.component(.weekOfYear, from: currentTime) != calendar.component(.weekOfYear, from: lastCandleDate)
                    case .month:
                        shouldCreateNewCandle = calendar.component(.month, from: currentTime) != calendar.component(.month, from: lastCandleDate)
                    @unknown default:
                        shouldCreateNewCandle = false
                    }
                } else {
                    shouldCreateNewCandle = true
                }
                
                if shouldCreateNewCandle {
                    print("✅ 새로운 캔들 생성됨: \(newDateLabel)")
                    let newCandle = CandleChartDataEntry(
                        x: Double(updatedEntries.count),
                        shadowH: livePrice.price,
                        shadowL: livePrice.price,
                        open: livePrice.price,
                        close: livePrice.price
                    )
                    updatedEntries.append(newCandle)
                    updatedDates.append(newDateLabel)
                } else {
                    // 기존 캔들 업데이트 (한 번 생성된 캔들은 계속 업데이트)
                    if let lastEntry = updatedEntries.last {
                        let updatedLastEntry = CandleChartDataEntry(
                            x: lastEntry.x,
                            shadowH: max(lastEntry.high, livePrice.price),
                            shadowL: min(lastEntry.low, livePrice.price),
                            open: lastEntry.open,
                            close: livePrice.price
                        )
                        updatedEntries[updatedEntries.count - 1] = updatedLastEntry
                    }
                }
                
                // 업데이트된 데이터를 차트에 반영
                self.chartDataRelay.accept((
                    updatedDates,
                    updatedEntries,
                    self.highestPriceRelay.value,
                    self.lowestPriceRelay.value,
                    IndexAxisValueFormatter(values: updatedDates)
                ))
                
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

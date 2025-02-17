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
    
    // 내부 Relay
    private let chartDataRelay = PublishRelay<(dates: [String], entries: [CandleChartDataEntry], highest: String, lowest: String, xAxisFormatter: AxisValueFormatter)>()
    private let currentPricesRelay = BehaviorRelay<[String: String]>(value: [:])
    private let priceChangeRatesRelay = BehaviorRelay<[String: String]>(value: [:])
    private let coinInfoRelay = BehaviorRelay<[String: String]>(value: [:])
    private let highestPriceRelay = BehaviorRelay<String>(value: "0")
    private let lowestPriceRelay = BehaviorRelay<String>(value: "0")
    private let imageSubject = PublishSubject<(String, UIImage?)>()
    
    init(exchange: Exchange?, selectedCoins: [MarketPrice]) {
        let selectedCoinsRelay = BehaviorRelay<[MarketPrice]>(value: selectedCoins)
        let candleIntervalRelay = BehaviorRelay<CandleInterval>(value: .day)
        self.input = Input(selectedCoins: selectedCoinsRelay, candleInterval: candleIntervalRelay)
        
        self.chartUseCase = ChartUseCase(exchange: exchange)
        
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
                let currentPricesDict = Dictionary(uniqueKeysWithValues: coins.map { ($0.symbol, "KRW \($0.price)") })
                let changeRatesDict = Dictionary(uniqueKeysWithValues: coins.map { ($0.symbol, "\($0.changeRate)%") })
                self.currentPricesRelay.accept(currentPricesDict)
                self.priceChangeRatesRelay.accept(changeRatesDict)
                
                let symbols = coins.map { $0.symbol }
                self.chartUseCase.fetchCoinDescriptions(for: symbols)
                    .subscribe(onSuccess: { descriptions in
                        self.coinInfoRelay.accept(descriptions)
                    })
                    .disposed(by: self.disposeBag)
                
                let interval = self.input.candleInterval.value
                self.chartUseCase.fetchChartData(for: firstCoin, interval: interval)
                    .subscribe(onNext: { data in
                        self.chartDataRelay.accept(data)
                        self.highestPriceRelay.accept(data.highest)
                        self.lowestPriceRelay.accept(data.lowest)
                    })
                    .disposed(by: self.disposeBag)
                
                if let image = ImageRepository.getImage(for: firstCoin.symbol) {
                    self.imageSubject.onNext((firstCoin.symbol, image))
                } else {
                    let defaultImage = UIImage(named: "default_coin")
                    self.imageSubject.onNext((firstCoin.symbol, defaultImage))
                }
            })
            .disposed(by: disposeBag)
        
        input.candleInterval.asObservable()
            .distinctUntilChanged()
            .withLatestFrom(input.selectedCoins.asObservable()) { (interval: $0, coins: $1) }
            .subscribe(onNext: { [weak self] tuple in
                guard let self = self, let firstCoin = tuple.coins.first else { return }
                self.chartUseCase.fetchChartData(for: firstCoin, interval: tuple.interval)
                    .subscribe(onNext: { data in
                        self.chartDataRelay.accept(data)
                        self.highestPriceRelay.accept(data.highest)
                        self.lowestPriceRelay.accept(data.lowest)
                    })
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }
    
    // 즐겨찾기 관련 기능 (Core Data 연동)
    func toggleFavorite(for coin: MarketPrice) {
        // 우선 현재 즐겨찾기 상태를 확인하여 추가 혹은 삭제를 수행
        isFavorite(coin)
            .take(1)
            .subscribe(onNext: { [weak self] isFav in
                guard let self = self else { return }
                if isFav {
                    // 즐겨찾기에서 삭제
                    CoreDataManager.shared.deleteCoin(symbol: coin.symbol, exchange: coin.exchange)
                        .subscribe(onCompleted: {
                            print("Removed \(coin.symbol) from favorites")
                            NotificationCenter.default.post(name: NSNotification.Name("FavoriteListUpdated"), object: nil)
                        })
                        .disposed(by: self.disposeBag)
                } else {
                    // 즐겨찾기 추가
                    CoreDataManager.shared.createCoin(marketPrice: coin)
                        .subscribe(onCompleted: {
                            print("Added \(coin.symbol) to favorites")
                            NotificationCenter.default.post(name: NSNotification.Name("FavoriteListUpdated"), object: nil)
                        })
                        .disposed(by: self.disposeBag)
                }
            })
            .disposed(by: disposeBag)
    }
    
    // 즐겨찾기 여부 확인
    func isFavorite(_ coin: MarketPrice) -> Observable<Bool> {
        return CoreDataManager.shared.fetchCoins()
            .map { coins in
                coins.contains { $0.symbol == coin.symbol && $0.exchange == coin.exchange }
            }
            .distinctUntilChanged()
    }
}




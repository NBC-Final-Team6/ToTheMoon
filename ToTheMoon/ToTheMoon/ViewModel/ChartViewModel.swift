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
    let exchange: Exchange?
    let selectedCoins: BehaviorSubject<[MarketPrice]>
    let candleInterval = BehaviorSubject<CandleInterval>(value: .day)

    // MARK: - Outputs
    let chartData = PublishSubject<([String], [CandleChartDataEntry])>()
    let highestPrice = BehaviorSubject<String>(value: "0")
    let lowestPrice = BehaviorSubject<String>(value: "0")
    let currentPrices = BehaviorSubject<[String: String]>(value: [:])
    let priceChangeRates = BehaviorSubject<[String: String]>(value: [:])
    let coinInfo = BehaviorSubject<[String: String]>(value: [:])
    let imageSubject = PublishSubject<(String, UIImage?)>()
    let chartXAxisFormatter = PublishSubject<AxisValueFormatter>()

    // MARK: - Dependencies
    private let disposeBag = DisposeBag()
    private let symbolService = SymbolService()
    private let services: [Exchange: Any]

    // MARK: - Initializer
    init(exchange: Exchange?, selectedCoins: [MarketPrice]) {
        self.exchange = exchange
        self.selectedCoins = BehaviorSubject(value: selectedCoins)

        self.services = [
            .bithumb: BithumbService(),
            .coinone: CoinOneService(),
            .korbit: KorbitService(),
            .upbit: UpbitService()
        ]

        setupBindings()
    }

    // MARK: - Setup Bindings
    private func setupBindings() {
        bindSelectedCoins()
        bindCandleInterval()
    }

    private func bindSelectedCoins() {
        selectedCoins
            .subscribe(onNext: { [weak self] coins in
                guard let self = self, let firstCoin = coins.first else { return }
                self.updatePriceInfo(coins)
                self.fetchAllCoinInfo(symbols: coins.map { $0.symbol })
                self.fetchCandles(for: firstCoin)
            })
            .disposed(by: disposeBag)
    }

    private func bindCandleInterval() {
        candleInterval
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, let firstCoin = try? self.selectedCoins.value().first else { return }
                self.fetchCandles(for: firstCoin)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - 가격 및 변동률 업데이트
    private func updatePriceInfo(_ coins: [MarketPrice]) {
        let currentPricesDict = Dictionary(uniqueKeysWithValues: coins.map { ($0.symbol, "KRW \($0.price)") })
        let priceChangeRatesDict = Dictionary(uniqueKeysWithValues: coins.map { ($0.symbol, "\($0.changeRate)%") })
        
        currentPrices.onNext(currentPricesDict)
        priceChangeRates.onNext(priceChangeRatesDict)
    }

    // MARK: - 모든 코인의 설명 가져오기
    private func fetchAllCoinInfo(symbols: [String]) {
        symbolService.fetchCoinIDMap()
            .flatMap { [weak self] _ -> Single<[String: String]> in
                guard let self = self else { return .just([:]) }
                
                let coinInfoRequests = symbols.map { symbol in
                    self.fetchCoinDescription(symbol: self.convertToCoinGeckoID(symbol), originalSymbol: symbol)
                        .map { ($0.symbol.uppercased(), $0.description.ko) }
                }
                
                return Single.zip(coinInfoRequests)
                    .map { Dictionary(uniqueKeysWithValues: $0) }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] coinDescriptions in
                self?.coinInfo.onNext(coinDescriptions)
            })
            .disposed(by: disposeBag)
    }

    private func convertToCoinGeckoID(_ symbol: String) -> String {
        return symbolService.symbolToIDMap[symbol.lowercased()] ?? symbol
    }

    private func fetchCoinDescription(symbol: String, originalSymbol: String) -> Single<SymbolData> {
        return symbolService.fetchCoinDataAll(coinSymbol: symbol)
            .catch { [weak self] _ in
                guard let self = self else { return .never() }
                return self.symbolService.fetchCoinDataAll(coinSymbol: originalSymbol)
            }
    }

    // MARK: - 캔들 데이터 가져오기
    func fetchCandles(for coin: MarketPrice) {
        guard let exchange = self.exchange, let service = services[exchange] else {
            self.chartData.onNext(([], []))
            return
        }

        guard let interval = try? self.candleInterval.value() else { return }
        let fetchObservable: Observable<[Candle]>

        switch service {
        case let service as BithumbService:
            fetchObservable = service.fetchCandles(symbol: coin.symbol, interval: interval, count: 50).asObservable()
        case let service as UpbitService:
            fetchObservable = service.fetchCandles(symbol: coin.symbol, interval: interval, count: 50).asObservable()
        case let service as CoinOneService:
            fetchObservable = service.fetchCandles(symbol: coin.symbol, interval: interval, count: 50).asObservable()
        case let service as KorbitService:
            fetchObservable = service.fetchCandles(symbol: coin.symbol, interval: interval, count: 50).asObservable()
        default:
            self.chartData.onNext(([], []))
            return
        }

        fetchObservable
            .subscribe(onNext: { [weak self] candles in
                self?.updateChartData(candles, interval: interval)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - 차트 데이터 업데이트
    private func updateChartData(_ candles: [Candle], interval: CandleInterval) {
        let timestamps = candles.map { TimeInterval($0.timestamp / 1000) }

        let formatter = DateFormatter()
        formatter.dateFormat = {
            switch interval {
            case .minute: return "HH:mm"
            case .day: return "M월 d일"
            case .week: return "M월 W주"
            case .month: return "YYYY년 M월"
            }
        }()

        let dates = timestamps
            .map { formatter.string(from: Date(timeIntervalSince1970: $0)) }
            .reversed()

        let entries = candles.enumerated().map { index, candle in
            CandleChartDataEntry(x: Double(index), shadowH: candle.high, shadowL: candle.low, open: candle.open, close: candle.close)
        }

        chartData.onNext((Array(dates), entries))
        chartXAxisFormatter.onNext(IndexAxisValueFormatter(values: Array(dates)))

        if let highest = candles.max(by: { $0.high < $1.high })?.high,
           let lowest = candles.min(by: { $0.low < $1.low })?.low {
            highestPrice.onNext("\(highest)")
            lowestPrice.onNext("\(lowest)")
        }
    }
}

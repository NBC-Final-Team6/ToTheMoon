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
    let candleInterval: BehaviorSubject<CandleInterval> = BehaviorSubject(value: .day)

    // MARK: - Outputs
    let chartData: PublishSubject<([String], [CandleChartDataEntry])> = PublishSubject()
    let highestPrice: BehaviorSubject<String> = BehaviorSubject(value: "0")
    let lowestPrice: BehaviorSubject<String> = BehaviorSubject(value: "0")
    let currentPrices: BehaviorSubject<[String: String]> = BehaviorSubject(value: [:])
    let priceChangeRates: BehaviorSubject<[String: String]> = BehaviorSubject(value: [:])
    let coinInfo: BehaviorSubject<[String: String]> = BehaviorSubject(value: [:]) // ✅ 모든 코인의 설명을 저장
    
    let imageSubject = PublishSubject<(String, UIImage?)>()

    // X축 포맷터
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
        selectedCoins
            .subscribe(onNext: { [weak self] coins in
                guard let self = self else { return }

                var currentPricesDict: [String: String] = [:]
                var priceChangeRatesDict: [String: String] = [:]

                coins.forEach { coin in
                    currentPricesDict[coin.symbol] = "KRW \(coin.price)"
                    priceChangeRatesDict[coin.symbol] = "\(coin.changeRate)%"
                }

                self.currentPrices.onNext(currentPricesDict)
                self.priceChangeRates.onNext(priceChangeRatesDict)

                self.fetchAllCoinInfo(symbols: coins.map { $0.symbol })
                self.fetchCandles(for: coins.first!)
            })
            .disposed(by: disposeBag)

        candleInterval
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, let coins = try? self.selectedCoins.value(), let firstCoin = coins.first else { return }
                self.fetchCandles(for: firstCoin)
            })
            .disposed(by: disposeBag)
        
        // ✅ 코인 설명 데이터가 변경될 때 UI 업데이트 강제 적용
        coinInfo
            .observe(on: MainScheduler.instance) // UI 업데이트는 반드시 Main Thread에서 실행
            .subscribe(onNext: { info in
                print("✅ [DEBUG] UI 업데이트됨: \(info)") // 디버깅 로그 추가
            })
            .disposed(by: disposeBag)
    }

    // MARK: - ✅ 모든 코인의 설명 가져오기 (전체 변환 적용)
    private func fetchAllCoinInfo(symbols: [String]) {
        var coinDescriptions: [String: String] = [:]

        self.symbolService.fetchCoinIDMap()
            .subscribe(onSuccess: { [weak self] in
                guard let self = self else { return }
                print("✅ [DEBUG] CoinGecko 코인 ID 매핑 로드 완료 (\(self.symbolService.symbolToIDMap.count)개)")

                Observable.from(symbols)
                    .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
                    .flatMap { symbol -> Single<SymbolData> in
                        let convertedSymbol = self.convertToCoinGeckoID(symbol)
                        return self.fetchCoinDescription(symbol: convertedSymbol, originalSymbol: symbol)
                            .retry(3)
                            .delay(.seconds(2), scheduler: MainScheduler.instance)
                    }
                    .observe(on: MainScheduler.instance)
                    .subscribe(onNext: { coin in
                        let description = (coin.description.ko.isEmpty == false) ? coin.description.ko : "설명 데이터를 불러올 수 없습니다."
                        coinDescriptions[coin.symbol.uppercased()] = description
                        print("✅ [DEBUG] \(coin.symbol) 설명 추가됨: \(description)")

                        DispatchQueue.main.async {
                            self.coinInfo.onNext(coinDescriptions)
                        }
                    }, onError: { error in
                        print("❌ ERROR: 설명 데이터 가져오기 실패 - \(error.localizedDescription)")
                    }, onCompleted: {
                        print("✅ [SUCCESS] 모든 코인 설명 데이터 로드 완료")
                    })
                    .disposed(by: self.disposeBag)
            }, onFailure: { error in
                print("❌ ERROR: 코인 ID 매핑 불러오기 실패 - \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - ✅ 심볼을 CoinGecko ID로 변환
    private func convertToCoinGeckoID(_ symbol: String) -> String {
        return symbolService.symbolToIDMap[symbol.lowercased()] ?? symbol
    }

    // MARK: - ✅ 코인 설명 가져오기
    private func fetchCoinDescription(symbol: String, originalSymbol: String) -> Single<SymbolData> {
        return symbolService.fetchCoinDataAll(coinSymbol: symbol)
            .do(onSuccess: { coin in
                print("✅ [DEBUG] 설명 데이터 응답 확인: \(coin.symbol) → \(coin.description.ko ?? "설명 없음")")
            })
            .catch { [weak self] _ in
                print("❌ ERROR: \(symbol) 설명 데이터 실패, 원본 심볼로 재시도: \(originalSymbol)")
                guard let self = self else { return Single.never() }
                return self.symbolService.fetchCoinDataAll(coinSymbol: originalSymbol)
                    .do(onSuccess: { coin in
                        print("✅ [DEBUG] 원본 심볼 설명 응답 확인: \(coin.symbol) → \(coin.description.ko ?? "설명 없음")")
                    })
                    .catch { _ in
                        print("❌ ERROR: \(originalSymbol) 설명 데이터 최종 실패")
                        return Single.just(SymbolData(
                            id: originalSymbol,
                            symbol: originalSymbol,
                            name: originalSymbol.uppercased(),
                            image: nil,
                            description: Description(ko: "설명 데이터를 불러올 수 없습니다.")
                        ))
                    }
            }
    }
    
    // MARK: - ✅ 캔들 데이터 가져오기
    private func fetchCandles(for coin: MarketPrice) {
        guard let exchange = self.exchange, let service = services[exchange] else {
            self.chartData.onNext(([], []))
            return
        }

        let interval = try? self.candleInterval.value() ?? .day
        let fetchObservable: Observable<[Candle]>

        switch service {
        case let service as BithumbService:
            fetchObservable = service.fetchCandles(symbol: coin.symbol, interval: interval!, count: 50).asObservable()
        case let service as UpbitService:
            fetchObservable = service.fetchCandles(symbol: coin.symbol, interval: interval!, count: 50).asObservable()
        case let service as CoinOneService:
            fetchObservable = service.fetchCandles(symbol: coin.symbol, interval: interval!, count: 50).asObservable()
        case let service as KorbitService:
            fetchObservable = service.fetchCandles(symbol: coin.symbol, interval: interval!, count: 50).asObservable()
        default:
            self.chartData.onNext(([], []))
            return
        }

        fetchObservable
            .subscribe(onNext: { [weak self] candles in
                self?.updateChartData(candles, interval: interval!)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - ✅ `updateChartData` 메서드 추가 (차트 데이터 업데이트)
    private func updateChartData(_ candles: [Candle], interval: CandleInterval) {
        let timestamps = candles.map { TimeInterval($0.timestamp / 1000) }

        let formatter = DateFormatter()
        switch interval {
        case .minute:
            formatter.dateFormat = "HH:mm"
        case .day:
            formatter.dateFormat = "M월 d일"
        case .week:
            formatter.dateFormat = "M월 W주"
        case .month:
            formatter.dateFormat = "YYYY년 M월"
        }

        var dates = timestamps.map { formatter.string(from: Date(timeIntervalSince1970: $0)) }
        dates.reverse()

        let entries = candles.enumerated().map { index, candle in
            CandleChartDataEntry(x: Double(index), shadowH: candle.high, shadowL: candle.low, open: candle.open, close: candle.close)
        }

        self.chartData.onNext((dates, entries))
        self.chartXAxisFormatter.onNext(IndexAxisValueFormatter(values: dates))

        if let highest = candles.max(by: { $0.high < $1.high })?.high,
           let lowest = candles.min(by: { $0.low < $1.low })?.low {
            self.highestPrice.onNext("\(highest)")
            self.lowestPrice.onNext("\(lowest)")
        }
    }
}

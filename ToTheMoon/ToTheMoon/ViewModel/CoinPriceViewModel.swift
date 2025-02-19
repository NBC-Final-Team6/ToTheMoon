//
//  CoinPriceViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import RxSwift
import RxCocoa

protocol CoinPriceViewModelInput {
    func selectExchange(_ exchange: Exchange)
    func selectCoinPrice(at index: Int)
}

protocol CoinPriceViewModelOutput {
    var coinPrices: Observable<[MarketPrice]> { get }
    var selectedCoinPrice: Observable<MarketPrice?> { get }
    var currentExchange: Observable<Exchange> { get }
    var currentExchangeValue: Exchange { get }
    var error: Observable<NetworkError> { get }
    var candles: Observable<[Candle]> { get }
    var candlesDict: Observable<[String: [Candle]]> { get }
}

protocol CoinPriceViewModelType {
    var inputs: CoinPriceViewModelInput { get }
    var outputs: CoinPriceViewModelOutput { get }
}

class CoinPriceViewModel: CoinPriceViewModelInput, CoinPriceViewModelOutput, CoinPriceViewModelType {
    var inputs: CoinPriceViewModelInput { return self }
    var outputs: CoinPriceViewModelOutput { return self }
    
    // MARK: - Private Properties
    private let disposeBag = DisposeBag()
    private let upbitService = UpbitService()
    private let bithumbService = BithumbService()
    private let coinoneService = CoinOneService()
    private let korbitService = KorbitService()
    private let symbolService = SymbolService()
    
    private var loadingSymbols = Set<String>()
    private let currentExchangeRelay = BehaviorRelay<Exchange>(value: .bithumb)
    private var priceTimer: Disposable?
    private var candleTimer: Disposable?
    private var coinImages: [String: UIImage] = [:]
    
    // MARK: - Subjects
    private let coinPricesRelay = BehaviorRelay<[MarketPrice]>(value: [])
    private let selectedCoinPriceSubject = BehaviorSubject<MarketPrice?>(value: nil)
    private let errorSubject = PublishSubject<NetworkError>()
    private let candlesRelay = BehaviorRelay<[Candle]>(value: [])
    private let candlesDictRelay = BehaviorRelay<[String: [Candle]]>(value: [:])
    private let imageSubject = PublishSubject<(String, UIImage?)>()
    
    // MARK: - Output
    var coinPrices: Observable<[MarketPrice]> { return coinPricesRelay.asObservable() }
    var selectedCoinPrice: Observable<MarketPrice?> { return selectedCoinPriceSubject.asObservable() }
    var currentExchange: Observable<Exchange> { return currentExchangeRelay.asObservable() }
    var currentExchangeValue: Exchange {
        return currentExchangeRelay.value
    }
    var error: Observable<NetworkError> { return errorSubject.asObservable() }
    var candles: Observable<[Candle]> { return candlesRelay.asObservable() }
    var candlesDict: Observable<[String: [Candle]]> { return candlesDictRelay.asObservable() }
    
    init() {
        currentExchangeRelay.accept(.bithumb)
        setupBindings()
        //        setupPriceTimer()
        setupCandleTimer()
        setupImageBinding()
        fetchAllCandlesOnce()
        fetchCoinPrices()
    }
    
    deinit {
        priceTimer?.dispose()
        candleTimer?.dispose()
    }
    
    func startTimers() {
        setupPriceTimer()
        fetchCoinPrices()
    }
    
    func stopTimers() {
        priceTimer?.dispose()
        priceTimer = nil
    }
    
    // 거래소 변경
    func selectExchange(_ exchange: Exchange) {
        currentExchangeRelay.accept(exchange)
        DispatchQueue.main.async { [weak self] in
            self?.fetchCoinPrices()
            self?.fetchAllCandlesOnce()
        }
    }
    
    // 코인 선택
    func selectCoinPrice(at index: Int) {
        guard index < coinPricesRelay.value.count else { return }
        selectedCoinPriceSubject.onNext(coinPricesRelay.value[index])
    }
    
    private func setupBindings() {
        coinPrices
            .skip(1)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] prices in
                guard !prices.isEmpty else { return }
                prices.forEach { price in
                    self?.fetchCandles(for: price.symbol)
                }
            })
            .disposed(by: disposeBag)
    }
    
    // 코인 가격은 1초마다 요청
    private func setupPriceTimer() {
        priceTimer?.dispose()
        priceTimer = Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.fetchCoinPrices()
            })
    }
    
    // 캔들 데이터는 최초 1회 요청
    private func setupCandleTimer() {
        candleTimer?.dispose()
        fetchAllCandlesOnce()
    }
    
    private func setupImageBinding() {
        imageSubject
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (symbol, image) in
                guard let self = self else { return }
                self.coinImages[symbol] = image
                
                var currentPrices = self.coinPricesRelay.value
                if let index = currentPrices.firstIndex(where: { $0.symbol == symbol }) {
                    var updatedPrice = currentPrices[index]
                    updatedPrice.image = image
                    currentPrices[index] = updatedPrice
                    self.coinPricesRelay.accept(currentPrices)
                }
            })
            .disposed(by: disposeBag)
    }
    
    // 캔들 데이터 초기 로드
    private func fetchAllCandlesOnce() {
        coinPricesRelay.value.forEach { price in
            fetchCandles(for: price.symbol)
        }
    }
    
    // 코인명만 보이게(KRW 글자 제외)
    private func extractCoinSymbol(_ symbol: String) -> String {
        let formatter = SymbolFormatter()
        return formatter.format(symbol: symbol)
    }
    
    // 코인 이미지 로드
    private func loadCoinImage(for symbol: String) {
        guard !loadingSymbols.contains(symbol) else { return }
        loadingSymbols.insert(symbol)
        
        symbolService.fetchCoinThumbImage(coinSymbol: symbol)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] image in
                guard let self = self else { return }
                self.loadingSymbols.remove(symbol)
                
                if let image = image {
                    var currentPrices = self.coinPricesRelay.value
                    if let index = currentPrices.firstIndex(where: { $0.symbol == symbol }) {
                        var updatedPrice = currentPrices[index]
                        updatedPrice.image = image
                        currentPrices[index] = updatedPrice
                        self.coinPricesRelay.accept(currentPrices)
                    }
                }
            }, onFailure: { [weak self] error in
                self?.loadingSymbols.remove(symbol)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - fetchCoinPrices
    // 코인 가격 데이터 가져오기
    private func fetchCoinPrices() {
        let service: Single<[MarketPrice]>
        
        switch currentExchangeRelay.value {
        case .upbit:
            service = upbitService.fetchMarketPrices()
        case .bithumb:
            service = bithumbService.fetchMarketPrices()
        case .coinone:
            service = coinoneService.fetchMarketPrices()
        case .korbit:
            service = korbitService.fetchMarketPrices()
        }
        
        service
            .map { marketPrices -> [MarketPrice] in
                marketPrices.map { price in
                    var modifiedPrice = price
                    modifiedPrice.symbol = self.extractCoinSymbol(price.symbol)
                    modifiedPrice.image = ImageRepository.getImage(for: modifiedPrice.symbol)
                    return modifiedPrice
                }
                .sorted { $0.quoteVolume > $1.quoteVolume }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] marketPrices in
                self?.coinPricesRelay.accept(marketPrices)
                
                marketPrices
                    .filter { ImageRepository.getImage(for: $0.symbol) == nil }
                    .forEach { price in
                        self?.loadCoinImage(for: price.symbol)
                    }
            }, onFailure: { [weak self] error in
                guard let self = self else { return }
                if let networkError = error as? NetworkError {
                    self.errorSubject.onNext(networkError)
                } else {
                    self.errorSubject.onNext(.unknownError)
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - fetchCandles
    private func fetchCandles(for symbol: String) {
        let service: Single<[Candle]>
        
        switch currentExchangeRelay.value {
        case .upbit:
            service = upbitService.fetchCandles(symbol: symbol, interval: .hour, count: 24)
        case .bithumb:
            service = bithumbService.fetchCandles(symbol: symbol, interval: .hour, count: 24)
        case .coinone:
            service = coinoneService.fetchCandles(symbol: symbol, interval: .hour, count: 24)
        case .korbit:
            service = korbitService.fetchCandles(symbol: symbol, interval: .hour, count: 24)
        }
        
        service
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] candles in
                guard let self = self else { return }
                var currentDict = self.candlesDictRelay.value
                currentDict[symbol] = candles
                self.candlesDictRelay.accept(currentDict)
            }, onFailure: { [weak self] error in
                guard let self = self else { return }
                if let networkError = error as? NetworkError {
                    self.errorSubject.onNext(networkError)
                } else {
                    self.errorSubject.onNext(.unknownError)
                }
            })
            .disposed(by: disposeBag)
    }
}

//
//  CoinPriceViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import RxSwift
import RxCocoa

class CoinPriceViewModel {
    
    private let disposeBag = DisposeBag()
    
    private let upbitService = UpbitService()
    private let bithumbService = BithumbService()
    private let coinoneService = CoinOneService()
    private let korbitService = KorbitService()
    private let symbolService = SymbolService()
    
    private var loadingSymbols = Set<String>()  // 중복 로딩 방지
    
    private var currentExchange: Exchange = .upbit
    private var timer: Disposable?
    
    // Output
    private(set) var coinPrices = BehaviorRelay<[MarketPrice]>(value: [])
    let selectedCoinPrice = PublishSubject<MarketPrice>()
    let error = PublishSubject<Error>()
    
    private var coinImages: [String: UIImage] = [:]
    private let imageSubject = PublishSubject<(String, UIImage?)>()
    
    init() {
        setupTimer()
        setupImageBinding()
    }
    
    deinit {
        timer?.dispose()
    }
    
    // 거래소 변경
    func selectExchange(_ exchange: Exchange) {
        currentExchange = exchange
        fetchCoinPrices()
    }
    
    // 코인 선택
    func selectCoinPrice(at index: Int) {
        guard index < coinPrices.value.count else { return }
        selectedCoinPrice.onNext(coinPrices.value[index])
    }
    
    // 타이머 설정
    private func setupTimer() {
        timer?.dispose()
        timer = Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.fetchCoinPrices()
            })
        
        timer?.disposed(by: disposeBag)
    }
    
    // 코인명만 보이게(KRW 글자 제외)
    private func extractCoinSymbol(_ symbol: String) -> String {
        let formatter = SymbolFormatter()
        return formatter.format(symbol: symbol)
    }
    
    // 이미지 바인딩 설정
    private func setupImageBinding() {
        imageSubject
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (symbol, image) in
                guard let self = self else { return }
                self.coinImages[symbol] = image
                
                // 현재 목록 업데이트
                var currentPrices = self.coinPrices.value
                if let index = currentPrices.firstIndex(where: { $0.symbol == symbol }) {
                    var updatedPrice = currentPrices[index]
                    updatedPrice.image = image
                    currentPrices[index] = updatedPrice
                    self.coinPrices.accept(currentPrices)
                }
            })
            .disposed(by: disposeBag)
    }
    
    // 코인 이미지 로드
    private func loadCoinImage(for symbol: String) {
        // 이미 로딩 중인 심볼은 스킵
        guard !loadingSymbols.contains(symbol) else { return }
        loadingSymbols.insert(symbol)
        
        print("Asset에 없는 이미지 로드 시도: \(symbol)")
        
        symbolService.fetchCoinThumbImage(coinSymbol: symbol)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] image in
                guard let self = self else { return }
                self.loadingSymbols.remove(symbol)
                
                if let image = image {
                    print("이미지 로드 성공: \(symbol)")
                    // 현재 목록 업데이트
                    var currentPrices = self.coinPrices.value
                    if let index = currentPrices.firstIndex(where: { $0.symbol == symbol }) {
                        var updatedPrice = currentPrices[index]
                        updatedPrice.image = image
                        currentPrices[index] = updatedPrice
                        self.coinPrices.accept(currentPrices)
                    }
                }
            }, onFailure: { [weak self] error in
                print("이미지 로드 실패: \(symbol), 에러: \(error.localizedDescription)")
                self?.loadingSymbols.remove(symbol)
            })
            .disposed(by: disposeBag)
    }
    
    // 코인 가격 데이터 가져오기
    private func fetchCoinPrices() {
        let service: Single<[MarketPrice]>
        
        switch currentExchange {
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
                    // Asset에서 이미지 가져오기
                    modifiedPrice.image = ImageRepository.getImage(for: modifiedPrice.symbol)
                    return modifiedPrice
                }
                .sorted { $0.quoteVolume > $1.quoteVolume }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] marketPrices in
                self?.coinPrices.accept(marketPrices)
                // Asset에 없는 코인에 대해서만 이미지 로드
                marketPrices
                    .filter { ImageRepository.getImage(for: $0.symbol) == nil }
                    .forEach { price in
                        self?.loadCoinImage(for: price.symbol)
                    }
            }, onFailure: { [weak self] error in
                self?.error.onNext(error)
            })
            .disposed(by: disposeBag)
    }
}

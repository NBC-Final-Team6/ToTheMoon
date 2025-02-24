//
//  CharViewController.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//


import UIKit
import RxSwift
import RxCocoa
import DGCharts
import SnapKit

class ChartViewController: UIViewController, UIGestureRecognizerDelegate {
    
    private let chartView = ChartView()
    private let viewModel: ChartViewModel
    private let manageFavoritesUseCase: ManageFavoritesUseCase
    private let disposeBag = DisposeBag()
    private var uiDisposeBag = DisposeBag()
    
    // 현재 선택된 시간 간격 (초기값 .day)
    private var selectedTimeFrame: CandleInterval = .day
    
    init(viewModel: ChartViewModel, manageFavoritesUseCase: ManageFavoritesUseCase = ManageFavoritesUseCase()) {
        print("DEBUG: Initializing ChartViewController with viewModel: \(viewModel)")
        self.viewModel = viewModel
        self.manageFavoritesUseCase = manageFavoritesUseCase
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupBindings()
        bindViewModel()
        bindSymbolImage()
        setupNavigationBar()
        navigationController?.navigationBar.isHidden = false
        
        // 기본 시간 간격 설정 (.day)
        updateSelectedTimeFrame(.day)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 웹소켓 연결 실행 (이전 화면이 닫힌 후 실행)
        guard let firstCoin = viewModel.input.selectedCoins.value.first else { return }
        viewModel.subscribeToRealTimeUpdates(for: firstCoin)
    }
    
    // MARK: - Navigation Bar 설정
    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = .text
        
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton
        
        // ✅ 스와이프 제스처 활성화 (뒤로 가기 허용)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func updateNavigationBarTitle(with coin: MarketPrice) {
        title = "\(coin.symbol.uppercased()) / \(coin.exchange)"
    }
    
    // MARK: - View 설정
    private func setupViews() {
        view.backgroundColor = .clear
        view.addSubview(chartView)
        chartView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func bindSymbolImage() {
        viewModel.input.selectedCoins
            .asObservable()
            .map { $0.first?.symbol }      // 첫 번째 코인의 심볼만 가져옴
            .distinctUntilChanged()          // 심볼이 바뀔 때만 업데이트
            .subscribe(onNext: { [weak self] symbol in
                guard let self = self, let symbol = symbol else { return }
                // ImageRepository에서 해당 심볼에 맞는 이미지를 가져오고,
                // 없으면 "default_coin" 이미지를 사용합니다.
                let image = ImageRepository.getImage(for: symbol) ?? UIImage(named: "default_coin")
                self.chartView.coinSymbolImageView.image = image
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Binding 설정 (입력, 즐겨찾기 등)
    private func setupBindings() {
        chartView.favoriteButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self,
                      let firstCoin = self.viewModel.input.selectedCoins.value.first else { return }
                self.viewModel.toggleFavorite(for: firstCoin)
            })
            .disposed(by: disposeBag)
        
        chartView.alarmButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigateToAlarmEdit()
            })
            .disposed(by: disposeBag)
        
        viewModel.input.selectedCoins
            .map { $0.first }
            .compactMap { $0 }
            .flatMap { [weak self] coin in
                self?.viewModel.isFavorite(coin) ?? Observable.just(false)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isFavorite in
                self?.updateFavoriteButtonUI(isFavorite: isFavorite)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateFavoriteButtonState),
            name: NSNotification.Name("FavoriteListUpdated"),
            object: nil
        )
    }
    
    private func navigateToAlarmEdit() {
        guard let firstCoin = viewModel.input.selectedCoins.value.first else { return }
        let alarmViewModel = AlarmEditViewModel(selectedCoin: firstCoin)
        print(firstCoin)
        let alarmViewController = AlarmEditViewController(viewModel: alarmViewModel)
        navigationController?.pushViewController(alarmViewController, animated: true)
    }
    
    private func toggleFavorite(for coin: MarketPrice) {
        manageFavoritesUseCase.toggleFavorite(coin)
            .subscribe(onError: { error in
                print("❌ 즐겨찾기 토글 실패: \(error)")
            }, onCompleted: {
                print("✅ 즐겨찾기 토글 완료: \(coin.symbol)")
                NotificationCenter.default.post(name: NSNotification.Name("FavoriteListUpdated"), object: nil)
            })
            .disposed(by: disposeBag)
    }

    @objc private func updateFavoriteButtonState() {
        guard let firstCoin = viewModel.input.selectedCoins.value.first else { return }
        manageFavoritesUseCase.isCoinSaved(firstCoin.symbol, exchange: firstCoin.exchange)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isFavorite in
                self?.updateFavoriteButtonUI(isFavorite: isFavorite)
            })
            .disposed(by: disposeBag)
    }
    
    private func updateFavoriteButtonUI(isFavorite: Bool) {
        let imageName = isFavorite ? "star.fill" : "star"
        chartView.favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
        chartView.favoriteButton.tintColor = isFavorite ? .yellow : .gray
        
        viewModel.input.selectedCoins
            .map { $0.first }
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] firstCoin in
                self?.updateUI(with: firstCoin)
                self?.updateNavigationBarTitle(with: firstCoin)
            })
            .disposed(by: disposeBag)
        
        viewModel.output.chartData
            .drive(onNext: { [weak self] chartData in
                self?.chartView.configureChart(dates: chartData.dates, dataEntries: chartData.entries)
            })
            .disposed(by: disposeBag)
        
        viewModel.output.highestPrice
            .drive(onNext: { [weak self] highest in
                self?.chartView.highestPriceValueLabel.text = highest
            })
            .disposed(by: disposeBag)
        
        viewModel.output.lowestPrice
            .drive(onNext: { [weak self] lowest in
                self?.chartView.lowestPriceValueLabel.text = lowest
            })
            .disposed(by: disposeBag)
        
        viewModel.output.image
            .drive(onNext: { [weak self] (symbol, image) in
                guard let self = self,
                      let firstCoin = self.viewModel.input.selectedCoins.value.first,
                      firstCoin.symbol == symbol else { return }
                self.chartView.coinSymbolImageView.image = image
            })
            .disposed(by: disposeBag)
        
        setupTimeFrameBindings()
        chartView.googleSearchButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.searchCoinOnGoogle()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - 시간 간격 버튼 바인딩
    private func setupTimeFrameBindings() {
        let timeButtons: [(UIButton, CandleInterval)] = [
            (chartView.minuteButton, .minute),
            (chartView.dayButton, .day),
            (chartView.weekButton, .week),
            (chartView.monthButton, .month)
        ]
        
        for (button, interval) in timeButtons {
            button.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.updateSelectedTimeFrame(interval)
                })
                .disposed(by: disposeBag)
        }
    }
    
    private func updateSelectedTimeFrame(_ newInterval: CandleInterval) {
        selectedTimeFrame = newInterval
        viewModel.input.candleInterval.accept(newInterval)
        
        let allButtons = [chartView.minuteButton, chartView.dayButton, chartView.weekButton, chartView.monthButton]
        for button in allButtons {
            button.backgroundColor = .container
            button.setTitleColor(.text, for: .normal)
        }
        
        switch newInterval {
        case .minute:
            chartView.minuteButton.backgroundColor = .blue.withAlphaComponent(0.3)
        case .day:
            chartView.dayButton.backgroundColor = .blue.withAlphaComponent(0.3)
        case .week:
            chartView.weekButton.backgroundColor = .blue.withAlphaComponent(0.3)
        case .month:
            chartView.monthButton.backgroundColor = .blue.withAlphaComponent(0.3)
        default:
            break
        }
    }
    
    private func searchCoinOnGoogle() {
        guard let firstCoin = viewModel.input.selectedCoins.value.first else { return }
        let coinName = firstCoin.symbol.uppercased()
        let searchQuery = "https://www.google.com/search?q=\(coinName)+코인"
        if let url = URL(string: searchQuery) {
            UIApplication.shared.open(url)
        }
    }
    
    private func bindViewModel() {
        viewModel.output.coinInfo
            .drive(onNext: { [weak self] info in
                self?.updateCoinDescription(info)
            })
            .disposed(by: disposeBag)
    }
    
    private func updateUI(with firstCoin: MarketPrice) {
        uiDisposeBag = DisposeBag()
        
        let coinSymbol = firstCoin.symbol
        let coinExchange = firstCoin.exchange
        chartView.coinNameLabel.text = "\(coinSymbol.uppercased()) (\(coinExchange))"
        
        viewModel.output.currentPrices
            .map { $0[firstCoin.symbol] ?? "0" }
            .distinctUntilChanged()
            .drive(chartView.currentPriceLabel.rx.text)
            .disposed(by: uiDisposeBag)
        
        viewModel.output.priceChangeRates
            .map { rates in
                let formattedRates = rates.mapValues { value in
                    if let doubleValue = Double(value.replacingOccurrences(of: "%", with: "")) {
                        return String(format: "%.2f%%", doubleValue)
                    }
                    return value
                }
                return formattedRates
            }
            .map { $0[firstCoin.symbol] ?? "0%" }
            .distinctUntilChanged()
            .drive(chartView.changeRateValueLabel.rx.text)
            .disposed(by: uiDisposeBag)
        
        viewModel.output.coinInfo
            .map { $0[firstCoin.symbol.uppercased()] ?? "설명 데이터를 가져올 수 없습니다." }
            .distinctUntilChanged()
            .drive(onNext: { [weak self] description in
                self?.chartView.digitalAssetDescriptionTextView.text = description
            })
            .disposed(by: uiDisposeBag)
    }
    
    private func updateCoinDescription(_ info: [String: String]) {
        DispatchQueue.main.async {
            if let firstKey = info.keys.first, let description = info[firstKey] {
                self.chartView.digitalAssetDescriptionTextView.text = description
            } else {
                self.chartView.digitalAssetDescriptionTextView.text = "설명 데이터 준비중"
            }
        }
    }
}

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

class ChartViewController: UIViewController {

    private let chartView = ChartView()
    private let viewModel: ChartViewModel
    private let disposeBag = DisposeBag()
    private var uiDisposeBag = DisposeBag()
    private let coinPriceViewModel: CoinPriceViewModel

    // 현재 선택된 시간 간격을 저장하는 변수
    private var selectedTimeFrame: CandleInterval = .day

    init(viewModel: ChartViewModel, coinPriceViewModel: CoinPriceViewModel) {
        print("DEBUG: Initializing ChartViewController with viewModel: \(viewModel)")
        self.viewModel = viewModel
        self.coinPriceViewModel = coinPriceViewModel
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
        setupNavigationBar()
        navigationController?.navigationBar.isHidden = false
        
        if let firstCoin = try? viewModel.selectedCoins.value().first {
            viewModel.fetchCandles(for: firstCoin)
        }
        
        updateSelectedTimeFrame(.day)
    }

    // 네비게이션 바 및 뒤로가기 버튼 설정
    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = .black // 뒤로가기 버튼 색상

        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"), // 뒤로가기 아이콘
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func setupViews() {
        view.backgroundColor = .clear
        view.addSubview(chartView)
        chartView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupBindings() {
        // 현재 선택된 첫 번째 코인 가져오기
        viewModel.selectedCoins
            .map { $0.first } // ✅ 첫 번째 코인만 가져옴
            .compactMap { $0 } // ✅ nil 방지
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] firstCoin in
                self?.updateUI(with: firstCoin)
            })
            .disposed(by: disposeBag)

        // 차트 데이터 바인딩
        viewModel.chartData
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] dates, entries in
                self?.chartView.configureChart(dates: dates, dataEntries: entries)
            })
            .disposed(by: disposeBag)

        viewModel.chartXAxisFormatter
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] formatter in
                self?.chartView.setXAxisFormatter(formatter)
            })
            .disposed(by: disposeBag)

        // 시간 버튼 바인딩 (RxSwift 활용)
        setupTimeFrameBindings()

        // 구글 검색 버튼 기능 추가
        chartView.googleSearchButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.searchCoinOnGoogle()
            })
            .disposed(by: disposeBag)
    }

    // 시간 간격 버튼 Rx 바인딩 (분, 일, 주, 월만)
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

    // 선택된 시간 프레임 업데이트 (버튼 강조)
    private func updateSelectedTimeFrame(_ newInterval: CandleInterval) {
        selectedTimeFrame = newInterval
        viewModel.candleInterval.onNext(newInterval)

        // 버튼 UI 업데이트
        let allButtons = [chartView.minuteButton, chartView.dayButton, chartView.weekButton, chartView.monthButton]
        for button in allButtons {
            button.backgroundColor = .container
            button.setTitleColor(.text, for: .normal)
        }

        switch newInterval {
        case .minute: chartView.minuteButton.backgroundColor = .blue.withAlphaComponent(0.3)
        case .day: chartView.dayButton.backgroundColor = .blue.withAlphaComponent(0.3)
        case .week: chartView.weekButton.backgroundColor = .blue.withAlphaComponent(0.3)
        case .month: chartView.monthButton.backgroundColor = .blue.withAlphaComponent(0.3)
        default: break
        }
    }

    // 구글 검색 버튼 기능 (해당 코인을 검색)
    private func searchCoinOnGoogle() {
        guard let firstCoin = try? viewModel.selectedCoins.value().first else { return }
        let coinName = firstCoin.symbol.uppercased()
        let searchQuery = "https://www.google.com/search?q=\(coinName)+코인"
        
        if let url = URL(string: searchQuery) {
            UIApplication.shared.open(url)
        }
    }

    // ViewModel과 UI 바인딩
    private func bindViewModel() {
        viewModel.coinInfo
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] info in
                self?.updateCoinDescription(info)
            })
            .disposed(by: disposeBag)
    }

    // UI 업데이트 함수
    private func updateUI(with firstCoin: MarketPrice) {
        // 기존 UI 바인딩 해제 후 새로운 DisposeBag 생성
        uiDisposeBag = DisposeBag()
        
        let coinSymbol = firstCoin.symbol
        let coinExchange = firstCoin.exchange

        // 제목 및 코인 페어 표시
        let coinTitleText = "\(coinSymbol) / \(coinExchange)"
        chartView.coinTitleLabel.text = coinTitleText
        chartView.coinNameLabel.text = "\(coinSymbol) (\(coinExchange))"

        // 가격 정보 바인딩 (중복 방지)
        viewModel.currentPrices
            .map { $0[firstCoin.symbol] ?? "0" }
            .distinctUntilChanged()
            .bind(to: chartView.currentPriceLabel.rx.text)
            .disposed(by: uiDisposeBag)

        viewModel.priceChangeRates
            .map { rates in
                let formattedRates = rates.mapValues { value in
                    if let doubleValue = Double(value.replacingOccurrences(of: "%", with: "")) {
                        return String(format: "%.2f%%", doubleValue) // ✅ 소수점 2자리까지 변환
                    }
                    return value
                }
                return formattedRates
            }
            .map { $0[firstCoin.symbol] ?? "0%" } // ✅ 특정 코인의 변동률만 가져옴
            .distinctUntilChanged()
            .bind(to: chartView.changeRateValueLabel.rx.text)
            .disposed(by: uiDisposeBag)

        // 최고가 / 최저가 업데이트
        viewModel.highestPrice
            .distinctUntilChanged()
            .bind(to: chartView.highestPriceValueLabel.rx.text)
            .disposed(by: uiDisposeBag)

        viewModel.lowestPrice
            .distinctUntilChanged()
            .bind(to: chartView.lowestPriceValueLabel.rx.text)
            .disposed(by: uiDisposeBag)
        
        // 심볼 이미지 적용 (기본 이미지 → 네트워크 이미지)
        let defaultImage = UIImage(named: "default_coin")

        if let cachedImage = ImageRepository.getImage(for: coinSymbol) {
            chartView.coinSymbolImageView.image = cachedImage
        } else {
            chartView.coinSymbolImageView.image = defaultImage

            viewModel.imageSubject
                .filter { $0.0 == coinSymbol }
                .map { $0.1 }
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] image in
                    self?.chartView.coinSymbolImageView.image = image ?? defaultImage
                })
                .disposed(by: uiDisposeBag)
        }

        // 디지털 자산 소개 업데이트
        viewModel.coinInfo
            .map { $0[firstCoin.symbol.uppercased()] ?? "설명 데이터를 가져올 수 없습니다." }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] description in
                self?.chartView.digitalAssetDescriptionTextView.text = description
            })
            .disposed(by: uiDisposeBag)
    }

    // 코인 설명 UI 업데이트 함수
    private func updateCoinDescription(_ info: [String: String]) {
        DispatchQueue.main.async {
            if let firstKey = info.keys.first, let description = info[firstKey] {
                self.chartView.digitalAssetDescriptionTextView.text = description
            } else {
                self.chartView.digitalAssetDescriptionTextView.text = "설명 데이터를 불러올 수 없습니다."
            }
        }
    }
}

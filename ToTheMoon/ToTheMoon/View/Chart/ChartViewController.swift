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
        setupNavigationBar()
        navigationController?.navigationBar.isHidden = false
        updateSelectedTimeFrame(.day)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let firstCoin = viewModel.input.selectedCoins.value.first else { return }
        viewModel.subscribeToRealTimeUpdates(for: firstCoin)
    }

    // MARK: - View 및 Navigation 설정

    private func setupViews() {
        view.backgroundColor = .clear
        view.addSubview(chartView)
        chartView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

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
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func updateNavigationBarTitle(with coin: MarketPrice) {
        title = "\(coin.symbol.uppercased()) / \(coin.exchange)"
    }

    // MARK: - Binding 설정

    private func setupBindings() {
        bindSymbolImage()
        bindFavoriteButton()
        bindSelectedCoin()
        bindChartData()
        bindCoinDescription()
        bindCoinDetails()
        bindTimeFrameButtons()
        bindGoogleSearch()
    }
    
    private func bindCoinDetails() {
        viewModel.output.coinDetails
            .drive(onNext: { [weak self] totalSupply, circulatingSupply, marketCap in
                self?.chartView.totalSupplyValueLabel.text = totalSupply
                self?.chartView.circulatingSupplyValueLabel.text = circulatingSupply
                self?.chartView.marketCapValueLabel.text = marketCap
            })
            .disposed(by: disposeBag)
    }

    private func bindSymbolImage() {
        viewModel.input.selectedCoins
            .asObservable()
            .map { $0.first?.symbol }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] symbol in
                let image = ImageRepository.getImage(for: symbol ?? "") ?? UIImage(named: "default_coin")
                self?.chartView.coinSymbolImageView.image = image
            })
            .disposed(by: disposeBag)
    }

    private func bindFavoriteButton() {
        chartView.favoriteButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self, let firstCoin = self.viewModel.input.selectedCoins.value.first else { return }
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

    private func bindSelectedCoin() {
        viewModel.input.selectedCoins
            .map { $0.first }
            .distinctUntilChanged { $0?.symbol == $1?.symbol }
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] firstCoin in
                self?.updateUI(with: firstCoin)
                self?.updateNavigationBarTitle(with: firstCoin)
                self?.viewModel.fetchAndUpdateAllCoinData(for: firstCoin.symbol) // ✅ 추가된 부분
                    .subscribe()
                    .disposed(by: self!.disposeBag)
            })
            .disposed(by: disposeBag)
    }

    private func bindChartData() {
        viewModel.output.chartData
            .drive(onNext: { [weak self] chartData in
                self?.chartView.configureChart(dates: chartData.dates, dataEntries: chartData.entries)
            })
            .disposed(by: disposeBag)

        viewModel.output.highestPrice
            .drive(chartView.highestPriceValueLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.output.lowestPrice
            .drive(chartView.lowestPriceValueLabel.rx.text)
            .disposed(by: disposeBag)
    }

    private func bindCoinDescription() {
        viewModel.output.coinInfo
            .drive(onNext: { [weak self] info in
                print("✅ [DEBUG] 전달된 설명 데이터: \(info)")
                self?.updateCoinDescription(info)
            })
            .disposed(by: disposeBag)
    }

    private func bindTimeFrameButtons() {
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

    private func bindGoogleSearch() {
        chartView.googleSearchButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.searchCoinOnGoogle()
            })
            .disposed(by: disposeBag)
    }

    // MARK: - 업데이트 메서드

    private func updateSelectedTimeFrame(_ newInterval: CandleInterval) {
        selectedTimeFrame = newInterval
        viewModel.input.candleInterval.accept(newInterval)

        let allButtons = [chartView.minuteButton, chartView.dayButton, chartView.weekButton, chartView.monthButton]
        allButtons.forEach {
            $0.backgroundColor = .container
            $0.setTitleColor(.text, for: .normal)
        }

        switch newInterval {
        case .minute: chartView.minuteButton.backgroundColor = .blue.withAlphaComponent(0.3)
        case .day: chartView.dayButton.backgroundColor = .blue.withAlphaComponent(0.3)
        case .week: chartView.weekButton.backgroundColor = .blue.withAlphaComponent(0.3)
        case .month: chartView.monthButton.backgroundColor = .blue.withAlphaComponent(0.3)
        default: break
        }
    }

    private func searchCoinOnGoogle() {
        guard let firstCoin = viewModel.input.selectedCoins.value.first else { return }
        let searchQuery = "https://www.google.com/search?q=\(firstCoin.symbol.uppercased())+코인"
        if let url = URL(string: searchQuery) {
            UIApplication.shared.open(url)
        }
    }

    private func updateUI(with firstCoin: MarketPrice) {
        uiDisposeBag = DisposeBag()
        chartView.coinNameLabel.text = "\(firstCoin.symbol.uppercased()) (\(firstCoin.exchange))"

        viewModel.output.currentPrices
            .map { $0[firstCoin.symbol] ?? "0" }
            .distinctUntilChanged()
            .drive(chartView.currentPriceLabel.rx.text)
            .disposed(by: uiDisposeBag)

        viewModel.output.priceChangeRates
            .map { $0[firstCoin.symbol] ?? "0%" }
            .distinctUntilChanged()
            .drive(chartView.changeRateValueLabel.rx.text)
            .disposed(by: uiDisposeBag)
    }

    private func updateCoinDescription(_ info: [String: String]) {
        DispatchQueue.main.async {
            if let description = info.values.first {
                print("✅ [DEBUG] 업데이트할 설명 데이터: \(description)")
                self.chartView.digitalAssetDescriptionTextView.text = description
            } else {
                self.chartView.digitalAssetDescriptionTextView.text = "설명 데이터를 가져올 수 없습니다."
            }
        }
    }
}

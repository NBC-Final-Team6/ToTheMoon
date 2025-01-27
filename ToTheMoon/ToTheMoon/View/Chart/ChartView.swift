//
//  CharView.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import SnapKit
import DGCharts

class ChartView: UIView {

    // MARK: - UI 컴포넌트
    
    // 스크롤뷰 추가
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    // 컨텐츠 뷰 추가 (스크롤뷰 내부)
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // 상단 제목 라벨
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "BTC / Upbit"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()

    // 차트
    private let candleStickChartView: CandleStickChartView = {
        let chartView = CandleStickChartView()
        chartView.legend.enabled = false
        chartView.rightAxis.enabled = false
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.granularity = 1
        chartView.dragEnabled = true
        chartView.pinchZoomEnabled = true
        return chartView
    }()

    // 현재 가격 라벨
    private let currentPriceLabel: UILabel = {
        let label = UILabel()
        label.text = "KRW: 160,000,000"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .numbersGreen
        label.textAlignment = .center
        return label
    }()

    // 상승/하락 상태를 나타내는 라벨
    private let priceTrendLabel: UILabel = {
        let label = UILabel()
        label.text = "+2.65%"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .numbersGreen
        label.textAlignment = .center
        return label
    }()
    
    
    private let minuteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("분", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .clear
        return button
    }()

    private let dayButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("일", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .clear
        return button
    }()

    private let weekButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("주", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .clear
        return button
    }()

    private let monthButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("월", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .clear
        return button
    }()

    // 최고가 상태를 나타내는 라벨
    private let highestPriceLabel: UILabel = {
        let label = UILabel()
        label.text = "최고가"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    // 최저가 상태를 나타내는 라벨
    private let lowestPriceLabel: UILabel = {
        let label = UILabel()
        label.text = "최저가"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    // 최고가 값을 표시하는 라벨
    private let highestPriceValueLabel: UILabel = {
        let label = UILabel()
        label.text = "160,000,000"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .numbersGreen
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    // 최저가 값을 표시하는 라벨
    private let lowestPriceValueLabel: UILabel = {
        let label = UILabel()
        label.text = "150,000,000"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .numbersRed
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    // 변동률 상태를 나타내는 라벨
    private let changeRateLabel: UILabel = {
        let label = UILabel()
        label.text = "변동률"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    // 변동률 값을 표시하는 라벨
    private let changeRateValueLabel: UILabel = {
        let label = UILabel()
        label.text = "2.86%"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    // 코인 정보를 표시하는 라벨
    private let CoinInformationLabel: UILabel = {
        let label = UILabel()
        label.text = "코인 정보"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    // 총 발행 수량을 표시하는 라벨
    private let totalIssuedQuantityLabel: UILabel = {
        let label = UILabel()
        label.text = "총 발행 수량"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    // 총 발행 수량 값을 표시하는 라벨
    private let totalIssuedQuantityValueLabel: UILabel = {
        let label = UILabel()
        label.text = "99,986,637,553"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    // 시가 총액을 표시하는 라벨
    private let marketCapitalizationLabel: UILabel = {
        let label = UILabel()
        label.text = "시가 총액"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    // 시가 총액 값을 표시하는 라벨
    private let marketCapitalizationValueLabel: UILabel = {
        let label = UILabel()
        label.text = "2,904조 4,294억"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    // 현재 유통량을 표시하는 라벨
    private let ccurrentCirculationLabel: UILabel = {
        let label = UILabel()
        label.text = "현재 유통량"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    // 현재 유통량 값을 표시하는 라벨
    private let ccurrentCirculationValueLabel: UILabel = {
        let label = UILabel()
        label.text = "57,564,441,098"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    // 코인 심볼 이미지
    private let coinSymbolImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "btc_icon") // 심볼 이미지 설정
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // BTC / KRW 텍스트 라벨
    private let coinPairLabel: UILabel = {
        let label = UILabel()
        label.text = "BTC / KRW"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()

    // 거래소 이름 (Upbit)
    private let exchangeLabel: UILabel = {
        let label = UILabel()
        label.text = "UpBit"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()

    // 구글에서 검색 버튼 라벨
    private let googleSearchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("구글에서 검색", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.setTitleColor(.blue, for: .normal)
        button.backgroundColor = .clear
        return button
    }()

    // 디지털 자산 소개 텍스트
    private let digitalAssetIntroLabel: UILabel = {
        let label = UILabel()
        label.text = "디지털 자산 소개"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()

    // 디지털 자산 소개 내용
    private let digitalAssetDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = """
        비트 코인은 ‘나가 모토 사토시(가명)’가 블록체인 기술을 기반으로 개발한 최초의 디지털 자산입니다. 기존 화폐와 달리 정부, 중앙 은행, 또는 금융기관의 개입 없이 알고리즘에 의해 발행되며, 거래내역은 P2P 네트워크에 참여한 사용자들에게 의해 검증되고 관리됩니다. 뛰어난 보안성과 제한된 발행량 덕분에 가장 대표적인 디지털 자산으로 자리 잡았습니다.

        비트코인은 디지털 금으로 비유되며, 탈중앙화와 투명성을 핵심 가치를 둡니다. 오늘날 많은 국가와 기업들이 이를 채택하거나 연구하고 있습니다. 비트코인은 높은 변동성을 가지고 있으나, 장기적인 가치를 보는 투자자들에게 매력적인 자산으로 평가받고 있습니다.

        비트코인의 주요 특징은 다음과 같습니다:
        1. 총 발행량: 비트코인의 총 발행량은 2,100만 개로 제한되어 있습니다.
        2. 보안성: 비트코인은 분산 네트워크를 통해 거래를 검증하고 관리합니다.
        3. 탈중앙화: 금융 기관이나 정부의 간섭 없이 자유롭게 거래 가능합니다.
        
        
        
        
        
        
        
        
        
        
        """
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .gray
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()

    // MARK: - 초기화

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 레이아웃 설정

    private func setupUI() {
        backgroundColor = .white

        // 제목, 가격, 상승/하락 라벨 추가 (스크롤되지 않음)
        addSubview(titleLabel)
        addSubview(currentPriceLabel)
        addSubview(priceTrendLabel)

        // 스크롤뷰 및 컨텐츠뷰 추가 (스크롤 가능)
        addSubview(scrollView)
        scrollView.addSubview(contentView)

        // 상단 제목 라벨 제약조건
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.centerX.equalToSuperview()
        }

        // 현재 가격 라벨 제약조건
        currentPriceLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(10)
        }

        // 상승/하락 라벨 제약조건
        priceTrendLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.trailing.equalToSuperview().inset(10)
        }

        // 스크롤뷰 제약조건
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(currentPriceLabel.snp.bottom).offset(10) // 가격 라벨 아래부터 스크롤
            make.leading.trailing.bottom.equalToSuperview()
        }

        // 컨텐츠뷰 제약조건
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView) // 스크롤뷰의 경계에 맞춤
            make.width.equalTo(scrollView) // 수직 스크롤을 유지하기 위해 너비 고정
        }

        // 디버깅 출력
        DispatchQueue.main.async {
            print("ScrollView Frame: \(self.scrollView.frame)")
            print("ContentView Frame: \(self.contentView.frame)")
            print("ContentView Subviews Count: \(self.contentView.subviews.count)")
        }

        // 나머지 뷰를 컨텐츠뷰에 추가
        contentView.addSubview(candleStickChartView)
        contentView.addSubview(minuteButton)
        contentView.addSubview(dayButton)
        contentView.addSubview(weekButton)
        contentView.addSubview(monthButton)
        contentView.addSubview(highestPriceLabel)
        contentView.addSubview(lowestPriceLabel)
        contentView.addSubview(highestPriceValueLabel)
        contentView.addSubview(lowestPriceValueLabel)
        contentView.addSubview(changeRateLabel)
        contentView.addSubview(changeRateValueLabel)
        contentView.addSubview(CoinInformationLabel)
        contentView.addSubview(coinSymbolImageView)
        contentView.addSubview(coinPairLabel)
        contentView.addSubview(exchangeLabel)
        contentView.addSubview(googleSearchButton)
        contentView.addSubview(digitalAssetIntroLabel)
        contentView.addSubview(digitalAssetDescriptionLabel)
        contentView.addSubview(totalIssuedQuantityLabel)
        contentView.addSubview(totalIssuedQuantityValueLabel)
        contentView.addSubview(marketCapitalizationLabel)
        contentView.addSubview(marketCapitalizationValueLabel)
        contentView.addSubview(ccurrentCirculationLabel)
        contentView.addSubview(ccurrentCirculationValueLabel)

        setupConstraintsForContentView()

        // 디버깅 출력
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("ScrollView ContentSize: \(self.scrollView.contentSize)")
            print("ContentView Frame after layout: \(self.contentView.frame)")
        }
    }
    
    private func setupConstraintsForContentView() {

        // 차트 뷰
        candleStickChartView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(30)
            make.leading.trailing.equalToSuperview().inset(10)
            make.height.equalTo(250)
        }

        minuteButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(35)
        }

        dayButton.snp.makeConstraints { make in
            make.top.equalTo(minuteButton.snp.top)
            make.leading.equalTo(minuteButton.snp.trailing).offset(70)
        }

        weekButton.snp.makeConstraints { make in
            make.top.equalTo(minuteButton.snp.top)
            make.leading.equalTo(dayButton.snp.trailing).offset(70)
        }

        monthButton.snp.makeConstraints { make in
            make.top.equalTo(minuteButton.snp.top)
            make.leading.equalTo(weekButton.snp.trailing).offset(70)
        }

        // "최고가" 텍스트 라벨
        highestPriceLabel.snp.makeConstraints { make in
            make.top.equalTo(candleStickChartView.snp.bottom).offset(15)
            make.leading.equalToSuperview().offset(20)
        }

        // "최저가" 텍스트 라벨
        lowestPriceLabel.snp.makeConstraints { make in
            make.top.equalTo(candleStickChartView.snp.bottom).offset(15)
            make.leading.equalTo(highestPriceLabel.snp.trailing).offset(108)
        }

        // 최고가 값 라벨
        highestPriceValueLabel.snp.makeConstraints { make in
            make.top.equalTo(highestPriceLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(20)
        }

        // 최저가 값 라벨
        lowestPriceValueLabel.snp.makeConstraints { make in
            make.top.equalTo(lowestPriceLabel.snp.bottom).offset(10)
            make.leading.equalTo(highestPriceLabel.snp.trailing).offset(108)
        }

        // "변동률" 텍스트 라벨
        changeRateLabel.snp.makeConstraints { make in
            make.top.equalTo(candleStickChartView.snp.bottom).offset(15)
            make.leading.equalTo(lowestPriceLabel.snp.trailing).offset(110)
        }

        // 변동률 값 라벨
        changeRateValueLabel.snp.makeConstraints { make in
            make.top.equalTo(changeRateLabel.snp.bottom).offset(10)
            make.leading.equalTo(lowestPriceLabel.snp.trailing).offset(110)
        }

        // "코인 정보" 텍스트 라벨
        CoinInformationLabel.snp.makeConstraints { make in
            make.top.equalTo(highestPriceValueLabel.snp.bottom).offset(30)
            make.leading.equalToSuperview().offset(20)
        }

        // 추가된 뷰의 레이아웃 (구글 검색, 디지털 자산 소개 등)
        coinSymbolImageView.snp.makeConstraints { make in
            make.top.equalTo(CoinInformationLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(20)
            make.width.height.equalTo(30)
        }

        coinPairLabel.snp.makeConstraints { make in
            make.top.equalTo(CoinInformationLabel.snp.bottom).offset(10)
            make.leading.equalTo(coinSymbolImageView.snp.trailing).offset(10)
        }

        exchangeLabel.snp.makeConstraints { make in
            make.top.equalTo(CoinInformationLabel.snp.bottom).offset(25)
            make.leading.equalTo(coinSymbolImageView.snp.trailing).offset(10)
        }

        googleSearchButton.snp.makeConstraints { make in
            make.top.equalTo(changeRateValueLabel.snp.bottom).offset(60)
            make.leading.equalTo(coinSymbolImageView.snp.trailing).offset(250)
        }

        // "총 발행 수량" 텍스트 라벨
        totalIssuedQuantityLabel.snp.makeConstraints { make in
            make.top.equalTo(coinSymbolImageView.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        // 총 발행 수량 값 라벨
        totalIssuedQuantityValueLabel.snp.makeConstraints { make in
            make.top.equalTo(totalIssuedQuantityLabel.snp.top)
            make.leading.equalTo(totalIssuedQuantityLabel.snp.trailing).offset(220)
        }

        // "시가 총액" 텍스트 라벨
        marketCapitalizationLabel.snp.makeConstraints { make in
            make.top.equalTo(totalIssuedQuantityLabel.snp.bottom).offset(5)
            make.leading.equalToSuperview().offset(20)
        }

        // 시가 총액 값 라벨
        marketCapitalizationValueLabel.snp.makeConstraints { make in
            make.top.equalTo(marketCapitalizationLabel.snp.top)
            make.leading.equalTo(totalIssuedQuantityLabel.snp.trailing).offset(220)
        }

        // "현재 유통량" 텍스트 라벨
        ccurrentCirculationLabel.snp.makeConstraints { make in
            make.top.equalTo(marketCapitalizationLabel.snp.bottom).offset(5)
            make.leading.equalToSuperview().offset(20)
        }

        // 현재 유통량 값 라벨
        ccurrentCirculationValueLabel.snp.makeConstraints { make in
            make.top.equalTo(ccurrentCirculationLabel.snp.top)
            make.leading.equalTo(totalIssuedQuantityLabel.snp.trailing).offset(220)
        }

        digitalAssetIntroLabel.snp.makeConstraints { make in
            make.top.equalTo(googleSearchButton.snp.bottom).offset(80)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        digitalAssetDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(digitalAssetIntroLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().offset(-20) // 마지막 요소의 bottom을 contentView와 연결
        }

    }

    // MARK: - 차트 데이터 설정
    func configureChart(dates: [String], dataEntries: [CandleChartDataEntry]) {
        let dataSet = CandleChartDataSet(entries: dataEntries, label: "")
        dataSet.decreasingColor = .red
        dataSet.increasingColor = .blue
        dataSet.shadowWidth = 1.5
        dataSet.drawValuesEnabled = false

        let data = CandleChartData(dataSet: dataSet)
        candleStickChartView.data = data

        candleStickChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: dates)
    }
    
    private lazy var timeButtons: [UIButton] = [minuteButton, dayButton, weekButton, monthButton]

    private func addTimeButtons() {
        for button in timeButtons {
            addSubview(button)
        }
    }
}


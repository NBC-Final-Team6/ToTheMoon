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
    
    // 상단 BTC/Upbit 라벨
    let coinTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "BTC/Upbit"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .text
        label.textAlignment = .center
        return label
    }()

    // 현재 가격 라벨
    let currentPriceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .numbersGreen
        label.textAlignment = .left
        return label
    }()

    // 새로운 시간 버튼 컨테이너 뷰 (1분, 일, 주, 월 버튼을 그룹화)
    private let timeSelectorView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }()
    
    // 코인 정보 컨테이너
    private let coinInfoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .container
        view.layer.cornerRadius = 10
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.borderWidth = 0.5
        return view
    }()

    // 코인 정보 StackView (코인 심볼 + 텍스트 + 버튼)
    private let coinInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.alignment = .center
        return stackView
    }()

    // 코인 심볼 이미지
    let coinSymbolImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "default_coin") // 기본 이미지 적용
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(30)
        }
        return imageView
    }()

    // 코인 이름 라벨
    let coinNameLabel: UILabel = {
        let label = UILabel()
        label.text = "BTC (Upbit)"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .text
        return label
    }()

    // 구글 검색 버튼
    let googleSearchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("구글에서 검색", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        button.setTitleColor(.blue, for: .normal)
        return button
    }()

    // 코인 정보 (총 발행 수량, 시가 총액, 현재 유통량)
    private let supplyInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 5
        return stackView
    }()

    let totalSupplyLabel = ChartView.createInfoLabel(title: "총 발행 수량", value: "99,986,676,553")
    let marketCapLabel = ChartView.createInfoLabel(title: "시가 총액", value: "2,904조 4,294억")
    let circulatingSupplyLabel = ChartView.createInfoLabel(title: "현재 유통량", value: "57,764,441,098")
    
    // 디지털 자산 소개 컨테이너
    private let digitalAssetContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .container
        view.layer.cornerRadius = 10
        return view
    }()

    // 디지털 자산 소개 텍스트
    let digitalAssetIntroLabel: UILabel = {
        let label = UILabel()
        label.text = "디지털 자산 소개"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .text
        return label
    }()

    // 디지털 자산 소개 내용 (UITextView로 변경)
    let digitalAssetDescriptionTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 12)
        textView.textColor = .text
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.text = """
    비트코인 나가모도 사토시 블라블라블라
    블라블라블라 나가모도 사토시 블라블라
    """
        return textView
    }()

    let minuteButton = ChartView.createTimeButton(title: "분")
    let dayButton = ChartView.createTimeButton(title: "일")
    let weekButton = ChartView.createTimeButton(title: "주")
    let monthButton = ChartView.createTimeButton(title: "월")

    // 차트 뷰
    private let candleStickChartView: CandleStickChartView = {
        let chartView = CandleStickChartView()
        chartView.legend.enabled = false
        chartView.rightAxis.enabled = false
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.granularity = 1
        chartView.dragEnabled = true
        chartView.pinchZoomEnabled = true
        chartView.backgroundColor = .background
        return chartView
    }()

    private let priceInfoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .container
        view.layer.cornerRadius = 10
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.borderWidth = 0.5
        return view
    }()
    
    private let priceInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        return stackView
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()

    // 스크롤 가능한 내용을 담을 StackView
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .fill
        return stackView
    }()

    let highestPriceLabel = ChartView.createPriceLabel(text: "최고가")
    let highestPriceValueLabel = ChartView.createPriceValueLabel(textColor: .green)
    let lowestPriceLabel = ChartView.createPriceLabel(text: "최저가")
    let lowestPriceValueLabel = ChartView.createPriceValueLabel(textColor: .red)
    let changeRateLabel = ChartView.createPriceLabel(text: "변동률")
    let changeRateValueLabel = ChartView.createPriceValueLabel(textColor: .text)

    // MARK: - 초기화
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI 설정
    private func setupUI() {
        backgroundColor = .background

        addSubview(coinTitleLabel)
        addSubview(currentPriceLabel)
        addSubview(timeSelectorView)

        // ✅ 스크롤뷰 추가
        addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        // ✅ 기존 UI 요소들을 contentStackView 안에 추가
        contentStackView.addArrangedSubview(candleStickChartView)
        contentStackView.addArrangedSubview(priceInfoContainerView)
        contentStackView.addArrangedSubview(coinInfoContainerView)
        contentStackView.addArrangedSubview(digitalAssetContainerView)

        priceInfoContainerView.addSubview(priceInfoStackView)

        let highestPriceStack = ChartView.createHorizontalStack(title: highestPriceLabel, value: highestPriceValueLabel)
        let lowestPriceStack = ChartView.createHorizontalStack(title: lowestPriceLabel, value: lowestPriceValueLabel)
        let changeRateStack = ChartView.createHorizontalStack(title: changeRateLabel, value: changeRateValueLabel)

        priceInfoStackView.addArrangedSubview(highestPriceStack)
        priceInfoStackView.addArrangedSubview(lowestPriceStack)
        priceInfoStackView.addArrangedSubview(changeRateStack)

        timeSelectorView.addArrangedSubview(minuteButton)
        timeSelectorView.addArrangedSubview(dayButton)
        timeSelectorView.addArrangedSubview(weekButton)
        timeSelectorView.addArrangedSubview(monthButton)

        // 코인 정보
        coinInfoContainerView.addSubview(coinInfoStackView)
        coinInfoStackView.addArrangedSubview(coinSymbolImageView)
        coinInfoStackView.addArrangedSubview(coinNameLabel)
        coinInfoStackView.addArrangedSubview(googleSearchButton)

        // 공급 정보
        coinInfoContainerView.addSubview(supplyInfoStackView)
        supplyInfoStackView.addArrangedSubview(totalSupplyLabel)
        supplyInfoStackView.addArrangedSubview(marketCapLabel)
        supplyInfoStackView.addArrangedSubview(circulatingSupplyLabel)

        // 디지털 자산 소개
        digitalAssetContainerView.addSubview(digitalAssetIntroLabel)
        digitalAssetContainerView.addSubview(digitalAssetDescriptionTextView)

        setupConstraints()
    }
    
    // MARK: - 레이아웃 설정
    private func setupConstraints() {
        coinTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(10)
            make.centerX.equalToSuperview()
        }

        currentPriceLabel.snp.makeConstraints { make in
            make.top.equalTo(coinTitleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(20)
        }
        
        timeSelectorView.snp.makeConstraints { make in
            make.top.equalTo(currentPriceLabel.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(30)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(timeSelectorView.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        contentStackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.width.equalTo(scrollView)
            make.bottom.equalToSuperview()
        }

        candleStickChartView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
            make.height.equalTo(250)
            
        }
        
        priceInfoContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.greaterThanOrEqualTo(120)
        }

        priceInfoStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }

        coinInfoContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
        }

        coinInfoStackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(10)
        }

        supplyInfoStackView.snp.makeConstraints { make in
            make.top.equalTo(coinInfoStackView.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview().inset(10)
        }

        digitalAssetContainerView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(150)
            make.leading.trailing.equalToSuperview().inset(10)
        }

        digitalAssetIntroLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(10)
        }

        digitalAssetDescriptionTextView.snp.makeConstraints { make in
            make.top.equalTo(digitalAssetIntroLabel.snp.bottom).offset(5)
            make.leading.trailing.bottom.equalToSuperview().inset(10)
        }
    }
    
    // MARK: - UI 생성 헬퍼 메서드
    private static func createHorizontalStack(title: UILabel, value: UILabel) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [title, value])
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        return stackView
    }
    
    private static func createVerticalInfoStack(title: String, value: String, valueColor: UIColor) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = .text
        titleLabel.textAlignment = .center

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.boldSystemFont(ofSize: 16)
        valueLabel.textColor = valueColor
        valueLabel.textAlignment = .center

        let stackView = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stackView.axis = .vertical
        stackView.spacing = 5
        stackView.alignment = .center
        return stackView
    }
    
    private static func createInfoLabel(title: String, value: String) -> UIView {
        let containerView = UIView()

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = .text

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.boldSystemFont(ofSize: 16)
        valueLabel.textColor = .text

        let stackView = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing

        containerView.addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }

        return containerView
    }
    
    private static func createPriceLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .text
        return label
    }

    private static func createPriceValueLabel(text: String = "", textColor: UIColor) -> UILabel {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = textColor
        return label
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

    func setXAxisFormatter(_ formatter: AxisValueFormatter) {
        candleStickChartView.xAxis.valueFormatter = formatter
    }

    // MARK: - 버튼 스타일 함수
    private static func createTimeButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(UIColor.text, for: .normal)
        button.backgroundColor = UIColor.container
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        return button
    }
}

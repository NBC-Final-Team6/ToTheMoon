//
//  AlarmEditView.swift
//  ToTheMoon
//
//  Created by Jimin on 2/20/25.
//

import UIKit
import SnapKit

class AlarmEditView: UIView {
    // MARK: - 코인 정보
    private let coinNameLabel: UILabel = {
        let label = UILabel()
        label.text = "노시스 (GNO/KRW)"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        return label
    }()
    
    private let coinInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = .container
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let currentPriceTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "현재가"
        label.font = .medium.regular()
        label.textColor = .text
        return label
    }()
    
    private let currentPriceLabel: UILabel = {
        let label = UILabel()
        label.text = "272,500 원"
        label.font = .medium.bold()
        label.textColor = .text
        label.textAlignment = .right
        return label
    }()
    
    private let priceChangeTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "전일대비"
        label.font = .medium.regular()
        label.textColor = .text
        return label
    }()
    
    private let priceChangeLabel: UILabel = {
        let label = UILabel()
        label.text = "-1.66%"
        label.font = .medium.bold()
        label.textColor = .numbersRed
        label.textAlignment = .right
        return label
    }()
    
    private let dayRangeTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "24시 최고/최저"
        label.font = .medium.regular()
        label.textColor = .text
        return label
    }()
    
    private let dayRangeLabel: UILabel = {
        let label = UILabel()
        label.text = "290,800 / 266,500"
        label.font = .medium.regular()
        label.textAlignment = .right
        return label
    }()
    
    // MARK: - 가격 지정
    private let priceSettingLabel: UILabel = {
        let label = UILabel()
        label.text = "가격 지정"
        label.font = .medium.regular()
        label.textColor = .text
        return label
    }()
    
    private let priceTextField: UITextField = {
        let textField = UITextField()
        textField.text = "272,500"
        textField.font = .systemFont(ofSize: 19, weight: .bold)
        textField.keyboardType = .numberPad
        textField.borderStyle = .none
        return textField
    }()
    
    private let decreaseButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "minus"), for: .normal)
        button.tintColor = .text
        button.backgroundColor = .container
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray5.cgColor
        return button
    }()
    
    private let increaseButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .text
        button.backgroundColor = .container
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray5.cgColor
        return button
    }()
    
    private let priceDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        return view
    }()
    
    // MARK: - 퍼센티지
    private let percentageLabel: UILabel = {
        let label = UILabel()
        label.text = "현재가 대비"
        label.font = .medium.regular()
        label.textColor = .text
        return label
    }()
    
    private let percentageContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let percentageValueLabel: UILabel = {
        let label = UILabel()
        label.text = "0%"
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .text
        return label
    }()
    
    private let percentageToggleButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        button.tintColor = .text
        return button
    }()
    
    private let percentageDropdownView: UIView = {
        let view = UIView()
        view.backgroundColor = .container
        view.layer.cornerRadius = 8
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.isHidden = true
        return view
    }()
    
    private lazy var percentageTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PercentageCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = true
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        tableView.rowHeight = 44
        tableView.layer.cornerRadius = 8
        tableView.clipsToBounds = true
        tableView.isScrollEnabled = true
        tableView.bounces = true
        return tableView
    }()
    
    private let percentages: [Int] = Array(1...30)
    private var isDropdownVisible = false
    
    private let percentageDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        return view
    }()
    
    // MARK: - 알림 목록
    private let alertHistoryLabel: UILabel = {
        let label = UILabel()
        label.text = "알림 목록"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .text
        return label
    }()
    
    private let alertHistoryDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        return view
    }()
    
    private lazy var alertHistoryScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.bounces = true
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let alertHistoryContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    // 테스트용 더미 데이터
    private var alertItems: [String] = [
        "273,200",
        "275,000",
        "268,000",
        "280,000",
        "265,000"
    ]
    
    // MARK: - 알림 추가 버튼
    private let addAlertButton: UIButton = {
        let button = UIButton()
        button.setTitle("알림추가", for: .normal)
        button.backgroundColor = .personel
        button.layer.cornerRadius = 10
        button.titleLabel?.font = .medium.bold()
        return button
    }()
    
    // MARK: - 초기화 및 UI 설정
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .background
        setupUI()
        setupActions()
        setupAlertHistoryItems()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupActions() {
        percentageToggleButton.addTarget(self, action: #selector(togglePercentageDropdown), for: .touchUpInside)
        percentageContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(togglePercentageDropdown)))
    }
    
    @objc private func togglePercentageDropdown() {
        isDropdownVisible.toggle()
        
        if isDropdownVisible {
            bringSubviewToFront(percentageDropdownView)
            percentageDropdownView.isHidden = false
            // 드롭다운 나타나는 애니메이션
            percentageDropdownView.transform = CGAffineTransform(scaleX: 1, y: 0.1)
            percentageDropdownView.alpha = 0
            
            UIView.animate(withDuration: 0.2) {
                self.percentageDropdownView.transform = .identity
                self.percentageDropdownView.alpha = 1
                self.percentageToggleButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
            }
        } else {
            // 드롭다운 사라지는 애니메이션
            UIView.animate(withDuration: 0.2, animations: {
                self.percentageDropdownView.transform = CGAffineTransform(scaleX: 1, y: 0.1)
                self.percentageDropdownView.alpha = 0
                self.percentageToggleButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
            }) { _ in
                self.percentageDropdownView.isHidden = true
            }
        }
    }
    
    // 선택된 퍼센트 업데이트
    private func selectPercentage(_ percentage: Int) {
        percentageValueLabel.text = "\(percentage)%"
        togglePercentageDropdown()
    }
    
    // 드롭다운 닫기
    func dismissDropdownIfNeeded() {
        if isDropdownVisible {
            togglePercentageDropdown()
        }
    }
    
    private func setupAlertHistoryItems() {
        // 기존 하위뷰 제거
        alertHistoryContentView.subviews.forEach { $0.removeFromSuperview() }
        
        var previousItem: UIView?
        
        for (index, item) in alertItems.enumerated() {
            let itemView = createAlertHistoryItem(price: item, index: index)
            alertHistoryContentView.addSubview(itemView)
            
            itemView.snp.makeConstraints { make in
                if let previousItem = previousItem {
                    make.top.equalTo(previousItem.snp.bottom).offset(16)
                } else {
                    make.top.equalToSuperview()
                }
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(40)
            }
            
            previousItem = itemView
        }
        
        // 마지막 아이템이 있을 경우 bottom constraint 설정
        if let lastItem = previousItem {
            lastItem.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
            }
        }
    }
    
    private func createAlertHistoryItem(price: String, index: Int) -> UIView {
        let itemView = UIView()
        
        let priceLabel = UILabel()
        priceLabel.text = "지정가: \(price) 원"
        priceLabel.font = .systemFont(ofSize: 15, weight: .regular)
        
        let deleteButton = UIButton()
        deleteButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        deleteButton.tintColor = .darkGray
        deleteButton.tag = index
        deleteButton.addTarget(self, action: #selector(deleteAlertItem(_:)), for: .touchUpInside)
        
        itemView.addSubview(priceLabel)
        itemView.addSubview(deleteButton)
        
        priceLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview()
        }
        
        deleteButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        return itemView
    }
    
    @objc private func deleteAlertItem(_ sender: UIButton) {
        let index = sender.tag
        guard index < alertItems.count else { return }
        
        alertItems.remove(at: index)
        setupAlertHistoryItems()
    }
    
    private func setupUI() {
        
        [coinNameLabel, coinInfoView, priceSettingLabel, priceTextField, decreaseButton, increaseButton, priceDivider, percentageLabel, percentageContainerView, percentageDropdownView, percentageDivider, alertHistoryLabel, alertHistoryDivider, alertHistoryScrollView, addAlertButton]
            .forEach { addSubview($0) }
        
        alertHistoryScrollView.addSubview(alertHistoryContentView)
        
        [currentPriceTitleLabel, currentPriceLabel, priceChangeTitleLabel, priceChangeLabel, dayRangeTitleLabel, dayRangeLabel]
            .forEach { coinInfoView.addSubview($0) }
        
        [percentageValueLabel, percentageToggleButton]
            .forEach { percentageContainerView.addSubview($0) }
        
        percentageDropdownView.addSubview(percentageTableView)
        
        // MARK: - 코인 정보 영역 레이아웃
        coinNameLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(20)
            make.leading.equalToSuperview().offset(20)
        }
        
        coinInfoView.snp.makeConstraints { make in
            make.top.equalTo(coinNameLabel.snp.bottom).offset(10)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(120)
        }
        
        currentPriceTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
        }
        
        currentPriceLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        priceChangeTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(currentPriceTitleLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
        }
        
        priceChangeLabel.snp.makeConstraints { make in
            make.top.equalTo(currentPriceLabel.snp.bottom).offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        dayRangeTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(priceChangeTitleLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
        }
        
        dayRangeLabel.snp.makeConstraints { make in
            make.top.equalTo(priceChangeLabel.snp.bottom).offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        // MARK: - 가격 지정 영역 레이아웃
        priceSettingLabel.snp.makeConstraints { make in
            make.top.equalTo(coinInfoView.snp.bottom).offset(30)
            make.leading.equalToSuperview().offset(16)
        }
        
        priceTextField.snp.makeConstraints { make in
            make.top.equalTo(priceSettingLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(decreaseButton.snp.leading).offset(-16)
        }
        
        decreaseButton.snp.makeConstraints { make in
            make.centerY.equalTo(priceTextField)
            make.trailing.equalTo(increaseButton.snp.leading).offset(-8)
            make.width.height.equalTo(36)
        }
        
        increaseButton.snp.makeConstraints { make in
            make.centerY.equalTo(priceTextField)
            make.trailing.equalToSuperview().offset(-16)
            make.width.height.equalTo(36)
        }
        
        priceDivider.snp.makeConstraints { make in
            make.top.equalTo(priceTextField.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(1)
        }
        
        // MARK: - 퍼센티지 영역 레이아웃
        percentageLabel.snp.makeConstraints { make in
            make.top.equalTo(priceDivider.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(16)
        }
        
        percentageContainerView.snp.makeConstraints { make in
            make.top.equalTo(percentageLabel.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(30)
        }
        
        percentageValueLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview()
        }
        
        percentageToggleButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        percentageDropdownView.snp.makeConstraints { make in
            make.top.equalTo(percentageContainerView.snp.bottom).offset(8)
            make.leading.trailing.equalTo(percentageContainerView)
            make.height.equalTo(220) // 약 5개 항목 표시
        }
        
        percentageTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        percentageDivider.snp.makeConstraints { make in
            make.top.equalTo(percentageContainerView.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(1)
        }
        
        // MARK: - 알림 목록 영역 레이아웃
        alertHistoryLabel.snp.makeConstraints { make in
            make.top.equalTo(percentageDivider.snp.bottom).offset(50)
            make.leading.equalToSuperview().offset(16)
        }
        
        alertHistoryDivider.snp.makeConstraints { make in
            make.top.equalTo(alertHistoryLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(1)
        }
        
        alertHistoryScrollView.snp.makeConstraints { make in
            make.top.equalTo(alertHistoryDivider.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.bottom.equalTo(addAlertButton.snp.top).offset(-16)
        }
        
        alertHistoryContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(alertHistoryScrollView.snp.width)
        }
        
        // MARK: - 알림 추가 버튼 레이아웃
        addAlertButton.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-24)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension AlarmEditView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return percentages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PercentageCell", for: indexPath)
        cell.backgroundColor = .container
        let percentage = percentages[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = "\(percentage)%"
        content.textProperties.font = .systemFont(ofSize: 15, weight: .regular)
        content.textProperties.color = .text
        cell.contentConfiguration = content
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let percentage = percentages[indexPath.row]
        selectPercentage(percentage)
    }
}

//
//  CoinPriceView.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import SnapKit

class CoinPriceView: UIView {
    
    // 앱 이름
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "ToTheMoon"
        label.textColor = .text
        label.textAlignment = .center
        label.font = UIFont.extraLarge.bold()
        return label
    }()
    
    // 거래소 5개 합친 스택뷰
    private let stackView: UIStackView = {
        let stackview = UIStackView()
        stackview.axis = .horizontal
        stackview.distribution = .equalSpacing
        stackview.alignment = .center
        stackview.spacing = 20
        return stackview
    }()
    
    let coinPriceTableView: UITableView = {
        let tableview = UITableView()
        tableview.register(CoinPriceTableViewCell.self, forCellReuseIdentifier: CoinPriceTableViewCell.identifier)
        tableview.backgroundColor = .container
        tableview.separatorStyle = .singleLine
        tableview.layer.cornerRadius = 30
        return tableview
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .background
        
        [titleLabel, stackView, coinPriceTableView]
            .forEach { addSubview($0) }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.centerX.equalToSuperview()
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(15)
            make.height.equalTo(((UIScreen.main.bounds.width - 100) / 4) + 26)
        }
        
        coinPriceTableView.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(10)
            make.bottom.equalTo(safeAreaLayoutGuide)
        }
        
        for (index, market) in MarketModel.items.enumerated() {
            let marketView = MarketView()
            marketView.configure(with: market)
            stackView.addArrangedSubview(marketView)
            
            if index == 0 {
                marketView.handleTap()
            }
        }
    }
}

extension CoinPriceView {
    func getMarketViews() -> [MarketView] {
        return stackView.arrangedSubviews.compactMap { $0 as? MarketView }
    }
    
    func resetMarketViews() {
        getMarketViews().forEach { $0.resetState() }
    }
}

// 거래소 화면 전환 시 맨 위로 스크롤
extension CoinPriceView {
    func scrollToTop() {
        coinPriceTableView.setContentOffset(.zero, animated: false)
    }
}

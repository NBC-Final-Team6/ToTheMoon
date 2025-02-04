//
//  CoinPriceTableViewCell.swift
//  ToTheMoon
//
//  Created by Jimin on 1/22/25.
//

import UIKit
import SnapKit
import DGCharts

class CoinPriceTableViewCell: UITableViewCell {
    
    static let identifier = "CoinPriceTableViewCell"
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        return imageView
    }()
    
    private let coinNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .text
        label.font = UIFont.medium.bold()
        label.textAlignment = .left
        return label
    }()
    
    private let marketNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .text
        label.font = UIFont.small.regular()
        label.textAlignment = .left
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.textColor = .text
        label.font = UIFont.medium.bold()
        label.textAlignment = .right
        return label
    }()
    
    private let priceChangeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.small.bold()
        label.textAlignment = .right
        return label
    }()
    
    private lazy var chartView: SimpleChartView = {
        let view = SimpleChartView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        backgroundColor = .container
        
        [logoImageView, coinNameLabel, marketNameLabel, priceLabel, priceChangeLabel, chartView]
            .forEach { contentView.addSubview($0) }
        
        logoImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        coinNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(logoImageView.snp.trailing).offset(10)
            make.top.equalToSuperview().offset(15)
        }
        
        marketNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(coinNameLabel)
            make.bottom.equalToSuperview().inset(15)
        }
        
        priceLabel.snp.makeConstraints { make in
            make.trailing.equalTo(chartView.snp.leading).offset(-10)
            make.top.equalToSuperview().offset(15)
        }
        
        priceChangeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(priceLabel)
            make.bottom.equalToSuperview().inset(15)
        }
        
        chartView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(40)
        }
        
    }
    
    func configure(with item: MarketPrice, candles: [Candle]? = nil) {
        
        logoImageView.backgroundColor = .systemGray6
        logoImageView.image = item.image
        
        coinNameLabel.text = item.symbol.uppercased()
        marketNameLabel.text = item.exchange
        priceLabel.text = "₩\(formatPrice(item.price))"
        
        if item.change == "RISE" {
            priceChangeLabel.text = "▲ \(String(format: "%.2f%%", item.changeRate))"
            priceChangeLabel.textColor = .numbersGreen
        } else {
            priceChangeLabel.text = "▼ \(String(format: "%.2f%%", abs(item.changeRate)))"  // abs()함수: 절대값을 구하는 함수
            priceChangeLabel.textColor = .numbersRed
        }
        
        if let candles = candles, !candles.isEmpty {
            let processedCandles = CandleChartDataManager.processCandles(candles)
            chartView.updateChart(with: processedCandles, changeRate: item.changeRate)
        } else {
            chartView.clearChart()
        }
    }
    
    private func formatPrice(_ price: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal  // 천 단위로 쉼표 찍어줌
        return numberFormatter.string(from: NSNumber(value: price)) ?? "0"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        logoImageView.image = nil
        chartView.clearChart()
    }
}

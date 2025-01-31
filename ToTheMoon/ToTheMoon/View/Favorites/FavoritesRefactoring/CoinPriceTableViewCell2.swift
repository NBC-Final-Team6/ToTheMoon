//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/28/25.
//

import UIKit
import SnapKit

class CoinPriceTableViewCell2: UITableViewCell {
    
    static let cellIdentifier = "CoinPriceTableViewCell2" // 이름 변경
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.backgroundColor = .red
        return imageView
    }()
    
    private let coinNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(named: "TextColor")
        label.font = .systemFont(ofSize: 15, weight: .bold)
        return label
    }()
    
    private let marketNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(named: "TextColor")
        label.font = .systemFont(ofSize: 13)
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(named: "TextColor")
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textAlignment = .right
        return label
    }()
    
    private let priceChangeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textAlignment = .right
        return label
    }()
    
    private let graphView: UIView = {
        let view = UIView()
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
        backgroundColor = UIColor(named: "ContainerColor")
        
        [logoImageView, coinNameLabel, marketNameLabel, priceLabel, priceChangeLabel, graphView]
            .forEach { contentView.addSubview($0) }
        
        logoImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        coinNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(logoImageView.snp.trailing).offset(10)
            make.top.equalToSuperview().offset(10)
            make.trailing.lessThanOrEqualTo(priceLabel.snp.leading).offset(-10)
        }
        
        marketNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(coinNameLabel)
            make.bottom.equalToSuperview().inset(10)
        }
        
        priceLabel.snp.makeConstraints { make in
            make.trailing.equalTo(graphView.snp.leading).offset(-10)
            make.top.equalToSuperview().offset(10)
        }
        
        priceChangeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(priceLabel)
            make.bottom.equalToSuperview().inset(10)
        }
        
        graphView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.width.equalTo(80)
            make.height.equalTo(45)
        }
    }
    
    func configure(with item: MarketPrice) {
        coinNameLabel.text = item.symbol
        marketNameLabel.text = item.exchange
        priceLabel.text = "₩\(formatPrice(item.price))"
        
        priceChangeLabel.text = item.change == "RISE"
            ? "▲ \(String(format: "%.2f%%", item.changeRate))"
            : "▼ \(String(format: "%.2f%%", abs(item.changeRate)))"
        priceChangeLabel.textColor = UIColor(named: item.change == "RISE" ? "NumbersGreenColor" : "NumbersRedColor")
    }
    
    private func formatPrice(_ price: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: price)) ?? "0"
    }
}

//
//  CoinPriceTableViewCell.swift
//  ToTheMoon
//
//  Created by Jimin on 1/22/25.
//

import UIKit
import SnapKit

class CoinPriceTableViewCell: UITableViewCell {
    
    static let identifier = "CoinPriceTableViewCell"
    
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
        label.textAlignment = .left
        return label
    }()
    
    private let marketNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(named: "TextColor")
        label.font = .systemFont(ofSize: 13)
        label.textAlignment = .left
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
        // TODO: 그래프 뷰
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
        }
        
        marketNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(coinNameLabel)
            make.bottom.equalToSuperview().inset(10)
        }
        
        priceLabel.snp.makeConstraints { make in
            make.trailing.equalTo(graphView.snp.leading).inset(10)
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
        // TODO: 로고, 그래프 뷰
        coinNameLabel.text = item.symbol
        marketNameLabel.text = item.exchange
        priceLabel.text = "₩\(formatPrice(item.price))"
        
        if item.change == "RISE" {
            priceChangeLabel.text = "▲ \(String(format: "%.2f%%", item.changeRate))"
            priceChangeLabel.textColor = UIColor(named: "NumbersGreenColor")
        } else {
            priceChangeLabel.text = "▼ \(String(format: "%.2f%%", abs(item.changeRate)))"  // abs()함수: 절대값을 구하는 함수
            priceChangeLabel.textColor = UIColor(named: "NumbersRedColor")
        }
    }
    
    private func formatPrice(_ price: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal  // 천 단위로 쉼표 찍어줌
        return numberFormatter.string(from: NSNumber(value: price)) ?? "0"
    }
}

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
        imageView.layer.cornerRadius = 15
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
        label.font = .systemFont(ofSize: 15)
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
        label.textColor = UIColor(named: "TextColor")
        label.font = .systemFont(ofSize: 13)
        label.textAlignment = .right
        return label
    }()
    
    // TODO: 그래프 뷰
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        [logoImageView, coinNameLabel, marketNameLabel, priceLabel, priceChangeLabel]
            .forEach {
            contentView.addSubview($0)
        }
        
        // TODO: 레이블 위치 잡기
        
    }
    
    func configure(with item: CoinPrice) {
        // TODO: 로고, 그래프 뷰
        coinNameLabel.text = item.coinName
        marketNameLabel.text = item.marketName
        priceLabel.text = "₩\(formatPrice(item.price))"
        
        let changeText = String(format: "%.2f%%", item.priceChange)
        priceChangeLabel.text = changeText
        priceChangeLabel.textColor = item.priceChange >= 0 ? UIColor(named: "NumbersGreenColor") : UIColor(named: "NumbersRedColor")
    }
    
    private func formatPrice(_ price: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal  // 천 단위로 쉼표 찍어줌
        return numberFormatter.string(from: NSNumber(value: price)) ?? "0"
    }
}

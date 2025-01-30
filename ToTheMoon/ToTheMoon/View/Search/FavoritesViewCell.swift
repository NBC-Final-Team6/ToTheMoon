//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/30/25.
//

import UIKit
import SnapKit

class FavoritesViewCell: UITableViewCell {
    
    static let identifier = "FavoritesViewCell"
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.backgroundColor = .clear
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
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("추가하기", for: .normal)
        button.setTitleColor(.text, for: .normal)
        button.backgroundColor = .personel
        button.titleLabel?.font = .medium.regular()
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        return button
    }()
    
    var addButtonAction: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        backgroundColor = UIColor(named: "ContainerColor")
        
        [logoImageView, coinNameLabel, marketNameLabel, priceLabel, priceChangeLabel, addButton]
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
            make.trailing.equalTo(addButton.snp.leading).offset(-10)
            make.top.equalToSuperview().offset(10)
        }
        
        priceChangeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(priceLabel)
            make.bottom.equalToSuperview().inset(10)
        }
        
        addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        
    }
    
    func configure(with item: MarketPrice) {
        // TODO: 로고, 그래프 뷰
        coinNameLabel.text = item.symbol
        marketNameLabel.text = item.exchange
        priceLabel.text = "₩\(formatPrice(item.price))"
        logoImageView.image = item.image
        
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
    
    @objc private func addButtonTapped() {
        addButtonAction?()
    }
}

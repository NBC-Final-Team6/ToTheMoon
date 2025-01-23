//
//  MarketView.swift
//  ToTheMoon
//
//  Created by Jimin on 1/22/25.
//

import UIKit
import SnapKit

class MarketView: UIView {
    
    private let marketImage: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.layer.cornerRadius = 30
        image.clipsToBounds = true
        image.backgroundColor = .red
        return image
    }()
    
    private let marketLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 15)
        label.textColor = UIColor(named: "TextColor")
        return label
    }()
    
    // 각 거래소별 스택뷰
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 2
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        stackView.addArrangedSubview(marketImage)
        stackView.addArrangedSubview(marketLabel)
        addSubview(stackView)
        
        marketImage.snp.makeConstraints { make in
            make.width.height.equalTo(60)
        }
        
        marketLabel.snp.makeConstraints { make in
            make.centerX.equalTo(marketImage.snp.centerX)
        }
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // 데이터 불러오기
    func configure(with item: MarketModel) {
//        marketImage.image = UIImage(named: item.imageName)
        marketImage.image = UIImage(systemName: item.imageName)
        marketLabel.text = item.title
    }
}

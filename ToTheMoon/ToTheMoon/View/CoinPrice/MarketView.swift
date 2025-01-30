//
//  MarketView.swift
//  ToTheMoon
//
//  Created by Jimin on 1/22/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class MarketView: UIView {
    
    let selectedExchange = PublishRelay<Exchange>()
    private var exchange: Exchange?
    
    private let marketImage: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.layer.cornerRadius = (UIScreen.main.bounds.width - 100) / 8
        image.clipsToBounds = true
        return image
    }()
    
    private let marketLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.medium.regular()
        label.textColor = .text
        return label
    }()
    
    // 각 거래소별 스택뷰
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 10
        return stackView
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGesture()
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 거래소 터치 변화
    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
    }
    
    @objc private func handleTap() {
        if let exchange = exchange {
            selectedExchange.accept(exchange)
            marketImage.tintColor = .personel
            marketLabel.textColor = .personel
        }
    }
    
    private func setupView() {
        stackView.addArrangedSubview(marketImage)
        stackView.addArrangedSubview(marketLabel)
        addSubview(stackView)
        
        marketImage.snp.makeConstraints { make in
            make.width.height.equalTo((UIScreen.main.bounds.width - 100) / 4)
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
        marketImage.image = UIImage(named: item.imageName)
        marketLabel.text = item.title
        
        switch item.title {
        case "업비트":
            exchange = .upbit
        case "빗썸":
            exchange = .bithumb
        case "코인원":
            exchange = .coinone
        case "코빗":
            exchange = .korbit
        default:
            break
        }
    }
    
    func resetState() {
        marketImage.tintColor = .text
        marketLabel.textColor = .text
    }
}

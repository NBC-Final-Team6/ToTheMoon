//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/27/25.
//

import UIKit
import SnapKit

final class NoFavoritesView: UIView {

    private let verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 20
        return stackView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "moon.fill"))
        imageView.tintColor = .personel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let noFavoritesLabel: UILabel = {
        let label = UILabel()
        label.text = "현재 관심 등록된 코인이 없습니다. \n현재 시세에서 관심있는 코인을 추가해 보세요."
        label.textColor = .text
        label.font = .medium.regular()
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 20
        return stackView
    }()
    
    let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("코인 추가하기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .personel
        button.layer.cornerRadius = 10
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .background
        
        // StackView에 구성 요소 추가
        [imageView, noFavoritesLabel].forEach { verticalStackView.addArrangedSubview($0) }
        buttonStackView.addArrangedSubview(addButton)
        
        // 뷰 계층 구조 설정
        addSubview(verticalStackView)
        addSubview(buttonStackView)
        
        // 제약 조건 설정
        verticalStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16) // 좌우 여백
        }
        
        imageView.snp.makeConstraints { make in
            make.height.equalTo(UIScreen.main.bounds.height * 0.3) // 화면 높이에 비례
            make.width.equalTo(imageView.snp.height) // 정사각형 비율
        }
        
        buttonStackView.snp.makeConstraints { make in
            make.top.equalTo(verticalStackView.snp.bottom).offset(40)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16) // 좌우 여백
        }
        
        addButton.snp.makeConstraints { make in
            make.height.equalTo(50)
            make.width.greaterThanOrEqualTo(150) // 최소 너비 설정
        }
    }
}

//
//  FavoritesViewController.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import SnapKit

final class TopFavoritesView: UIView {
    
    let logoLabel: UILabel = {
        let label = UILabel()
        label.text = "ToTheMoon"
        label.textColor = .text
        label.font = .extraLarge.bold()
        return label
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "관심목록"
        label.textColor = .text
        label.font = .large.bold()
        return label
    }()
    
    let countLabel: UILabel = {
        let label = UILabel()
        label.text = "(0)"
        label.textColor = .text
        label.font = .medium.regular()
        return label
    }()
    
    let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("선택삭제", for: .normal)
        button.tintColor = .text
        return button
    }()
    
    let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        button.tintColor = .text
        return button
    }()
    
    let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
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
        
        [logoLabel,
         searchButton,
         titleLabel,
         countLabel,
         deleteButton,
         contentView].forEach { addSubview($0) }
        
        logoLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.centerX.equalToSuperview()
        }
        
        searchButton.snp.makeConstraints { make in
            make.centerY.equalTo(logoLabel)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(logoLabel.snp.bottom).offset(28)
            make.leading.equalToSuperview().offset(20)
        }
        
        countLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
        }
        
        deleteButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        contentView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

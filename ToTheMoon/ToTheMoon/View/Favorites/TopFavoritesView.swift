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
        label.font = .large.regular()
        return label
    }()
    
    let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        button.tintColor = .text
        return button
    }()
    
    let tabCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.register(TabCell.self, forCellWithReuseIdentifier: "TabCell")
        return collectionView
    }()
    
    let underlineView: UIView = {
        let view = UIView()
        view.backgroundColor = .personel
        return view
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
         tabCollectionView,
         underlineView,
         contentView].forEach { addSubview($0) }
        
        logoLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(10)
            make.centerX.equalToSuperview()
        }
        
        searchButton.snp.makeConstraints { make in
            make.centerY.equalTo(logoLabel)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        tabCollectionView.snp.makeConstraints { make in
            make.top.equalTo(logoLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(40)
        }
        
        underlineView.snp.makeConstraints { make in
            make.bottom.equalTo(tabCollectionView.snp.bottom)
            make.height.equalTo(2)
        }
        
        contentView.snp.makeConstraints { make in
            make.top.equalTo(tabCollectionView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

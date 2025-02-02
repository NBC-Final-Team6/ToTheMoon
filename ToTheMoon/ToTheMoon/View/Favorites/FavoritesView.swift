//
//  FavoritesViewController.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import SnapKit

final class FavoritesView: UIView {
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
    
    let sortStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        return stackView
    }()

    let sortLabel: UILabel = {
        let label = UILabel()
        label.text = "전체 0"
        label.textColor = .text
        label.font = .medium.regular()
        return label
    }()

    let sortToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("인기순 ▼", for: .normal)
        button.setTitleColor(.text, for: .normal)
        button.titleLabel?.font = .medium.regular()
        return button
    }()

    let verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 20
        return stackView
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "moon.fill"))
        imageView.tintColor = .personel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let noFavoritesLabel: UILabel = {
        let label = UILabel()
        label.text = "현재 관심 등록된 코인이 없습니다. \n현재 시세에서 관심있는 코인을 추가해 보세요."
        label.textColor = .text
        label.font = .medium.regular()
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        return stackView
    }()
    
    let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("코인 추가하기", for: .normal)
        button.setTitleColor(.text, for: .normal)
        button.backgroundColor = .personel
        button.layer.cornerRadius = 10
        return button
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .background
        tableView.isHidden = true
        return tableView
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
        
        [sortLabel, sortToggleButton].forEach { sortStackView.addArrangedSubview($0) }
        [imageView, noFavoritesLabel].forEach { verticalStackView.addArrangedSubview($0) }
        buttonStackView.addArrangedSubview(addButton)
        
        [logoLabel,
         searchButton,
         tabCollectionView,
         underlineView,
         sortStackView,
         verticalStackView,
         tableView,
         buttonStackView].forEach { addSubview($0) }

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
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        
        underlineView.snp.makeConstraints { make in
            make.height.equalTo(2)
        }

        sortStackView.snp.makeConstraints { make in
            make.top.equalTo(tabCollectionView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        verticalStackView.snp.makeConstraints { make in
            make.top.equalTo(sortStackView.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(sortStackView.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        imageView.snp.makeConstraints { make in
            let screenHeight = UIScreen.main.bounds.height
            make.height.equalTo(screenHeight * 0.3)
            make.width.equalTo(imageView.snp.height)
        }

        buttonStackView.snp.makeConstraints { make in
            make.top.equalTo(verticalStackView.snp.bottom).offset(92)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        addButton.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
    }
    
    func updateViewStates(isSearchButtonHidden: Bool, isTableViewHidden: Bool, isVerticalStackHidden: Bool, isButtonStackHidden: Bool) {
        searchButton.isHidden = isSearchButtonHidden
        tableView.isHidden = isTableViewHidden
        verticalStackView.isHidden = isVerticalStackHidden
        buttonStackView.isHidden = isButtonStackHidden
    }
    
    func updateSortLabel(with count: Int) {
        sortLabel.text = "전체 \(count)"
    }
}

//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/28/25.
//

import UIKit
import SnapKit

final class PopularCurrencyTableView: UIView {
    
    let tableView: UITableView = {
        let tableview = UITableView()
        tableview.backgroundColor = .container
        tableview.layer.cornerRadius = 30
        return tableview
    }()

    let favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("관심목록에 추가", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .personel
        button.layer.cornerRadius = 10
        button.alpha = 0
        button.titleLabel?.font = .medium.bold()
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UIColor(named: "BackgroundColor")
        
        [tableView, favoriteButton].forEach { addSubview($0) }
        
        tableView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(10)
        }
        
        favoriteButton.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-20)
            make.centerX.equalToSuperview()
            make.width.greaterThanOrEqualTo(150)
            make.height.equalTo(50)
        }
        
        tableView.register(CoinPriceTableViewCell.self, forCellReuseIdentifier: CoinPriceTableViewCell.identifier)
    }
}


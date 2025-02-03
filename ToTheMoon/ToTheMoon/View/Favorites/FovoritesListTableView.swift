//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/28/25.
//

import UIKit
import SnapKit

final class FovoritesListTableView: UIView {
    
    let tableView: UITableView = {
        let tableview = UITableView()
        tableview.backgroundColor = .container
        tableview.layer.cornerRadius = 30
        return tableview
    }()
    
    let floatingButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .personel
        button.setTitle("+", for: .normal)
        button.setTitleColor(.text, for: .normal)
        button.titleLabel?.font = .large.bold()
        button.layer.cornerRadius = 30
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 2, height: 2)
        button.layer.shadowRadius = 4
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
        
        [ tableView, floatingButton ].forEach{ addSubview($0) }
        
        tableView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(10)
        }
        
        floatingButton.snp.makeConstraints { make in
            make.width.height.equalTo(60)
            make.bottom.equalToSuperview().inset(20)
            make.trailing.equalToSuperview().inset(20)
        }
        
        tableView.register(CoinPriceTableViewCell.self, forCellReuseIdentifier: CoinPriceTableViewCell.identifier)
    }
}

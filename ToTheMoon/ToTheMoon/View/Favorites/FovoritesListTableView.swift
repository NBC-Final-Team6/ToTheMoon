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
        
        [ tableView ].forEach{ addSubview($0) }
        
        tableView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(10)
        }
        
        tableView.register(CoinPriceTableViewCell.self, forCellReuseIdentifier: CoinPriceTableViewCell.identifier)
    }
}

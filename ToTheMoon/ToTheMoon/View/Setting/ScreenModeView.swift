//
//  ScreenModeView.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import SnapKit

class ScreenModeView: UIView {
    
    let backButton: UIButton = {
        let button = UIButton()
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        let largeImage = UIImage(systemName: "chevron.left", withConfiguration: largeConfig)
        button.setImage(largeImage, for: .normal)
        button.tintColor = UIColor(named: "TextColor")
        button.contentEdgeInsets = .zero
        return button
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "화면 모드 설정"
        label.textColor = UIColor(named: "TextColor")
        label.font = .extraLarge.bold()
        label.textAlignment = .center
        return label
    }()

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor(named: "ContainerColor")
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        tableView.layer.cornerRadius = 20
        tableView.separatorColor = UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1)
        tableView.isScrollEnabled = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ScreenModeCell")
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
        backgroundColor = UIColor(named: "BackgroundColor")

        addSubview(backButton)
        addSubview(titleLabel)
        addSubview(tableView)

        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalTo(safeAreaLayoutGuide).offset(10)
            make.width.height.equalTo(40)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(175)
        }
    }
}

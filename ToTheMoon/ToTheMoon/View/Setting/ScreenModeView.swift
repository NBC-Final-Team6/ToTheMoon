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
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .white
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return button
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "화면 모드 설정"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 30)
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
            make.leading.equalToSuperview().offset(10)
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
            make.height.equalTo(180)
        }
    }
}

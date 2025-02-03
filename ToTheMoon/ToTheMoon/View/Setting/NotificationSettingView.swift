//
//  NotificationSettingView.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import SnapKit

class NotificationSettingView: UIView {

    let backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .white
        return button
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "알림 설정"
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textAlignment = .center
        return label
    }()

    let notificationSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.isOn = true
        return toggle
    }()

    private let notificationLabel: UILabel = {
        let label = UILabel()
        label.text = "알림 허용"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        return label
    }()

    private let notificationContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(named: "ContainerColor")
        view.layer.cornerRadius = 20
        return view
    }()

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor(named: "ContainerColor")
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        tableView.separatorColor = UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1)
        tableView.layer.cornerRadius = 20
        tableView.isScrollEnabled = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NotificationStyleCell")
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

        let navigationContainer = UIView()
        addSubview(navigationContainer)
        navigationContainer.addSubview(backButton)
        navigationContainer.addSubview(titleLabel)

        addSubview(notificationContainer)
        notificationContainer.addSubview(notificationLabel)
        notificationContainer.addSubview(notificationSwitch)

        addSubview(tableView)

        navigationContainer.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }

        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(60)
        }

        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        notificationContainer.snp.makeConstraints { make in
            make.top.equalTo(navigationContainer.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(60)
        }

        notificationLabel.snp.makeConstraints { make in
            make.leading.equalTo(notificationContainer).offset(20)
            make.centerY.equalTo(notificationContainer)
        }

        notificationSwitch.snp.makeConstraints { make in
            make.trailing.equalTo(notificationContainer).offset(-20)
            make.centerY.equalTo(notificationContainer)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(notificationContainer.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(200)
        }
    }
}

//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit

class NotificationSettingViewController: UIViewController {

    private let notificationView = NotificationSettingView()
    private let options = ["소리만", "소리와 진동", "진동", "무음"]
    private var selectedOptionIndex = 0

    override func loadView() {
        self.view = notificationView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupActions()
        setupTableView()
        navigationController?.navigationBar.isHidden = true
    }

    private func setupActions() {
        notificationView.backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)

        notificationView.notificationSwitch.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
    }

    private func setupTableView() {
        notificationView.tableView.delegate = self
        notificationView.tableView.dataSource = self
    }
    
    @objc private func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }

    @objc private func switchValueChanged() {
        let isOn = notificationView.notificationSwitch.isOn
        print("알림 허용: \(isOn ? "켜짐" : "꺼짐")")
    }
}

extension NotificationSettingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationStyleCell", for: indexPath)
        cell.textLabel?.text = options[indexPath.row]
        cell.textLabel?.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        cell.textLabel?.textColor = .white
        cell.backgroundColor = .clear

        cell.accessoryType = (indexPath.row == selectedOptionIndex) ? .checkmark : .none
        return cell
    }
}

extension NotificationSettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedOptionIndex = indexPath.row
        tableView.reloadData()
        print("선택된 알림 스타일: \(options[selectedOptionIndex])")
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == options.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: cell.bounds.width)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        }
    }
}

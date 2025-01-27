//
//  SettingViewController.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit

class SettingViewController: UIViewController, UITableViewDelegate {
    
    private let settingView = SettingView()
    private let settings: [String] = ["알림 설정", "화면 모드 설정", "앱 정보"]

    override func loadView() {
        self.view = settingView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    private func setupTableView() {
        settingView.tableView.delegate = self
        settingView.tableView.dataSource = self
    }
}

extension SettingViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        cell.textLabel?.text = settings[indexPath.row]
        cell.textLabel?.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        cell.textLabel?.textColor = UIColor(named: "TextColor")
        cell.backgroundColor = .clear
        return cell
    }
}


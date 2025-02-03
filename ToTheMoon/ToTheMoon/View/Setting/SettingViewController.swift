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
        navigationController?.navigationBar.isHidden = true
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
        cell.textLabel?.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        cell.textLabel?.textColor = UIColor(named: "TextColor")
        cell.backgroundColor = .clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            let notificationVC = NotificationSettingViewController()
            navigationController?.pushViewController(notificationVC, animated: true)
        case 1:
            let screenModeVC = ScreenModeViewController()
            navigationController?.pushViewController(screenModeVC, animated: true)
        case 2:
            let informationVC = InformationViewController()
            navigationController?.pushViewController(informationVC, animated: true)
        default:
            break
        }
    }
}




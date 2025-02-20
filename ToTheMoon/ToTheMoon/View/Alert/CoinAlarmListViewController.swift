//
//  Untitled 2.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/20/25.
//

import UIKit
import SnapKit

class CoinAlarmListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let tableView = UITableView()
    private var alarms: [CoinAlarm] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadAlarms()
    }

    private func setupUI() {
        title = "코인 알람"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, target: self, action: #selector(addAlarm)
        )

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func loadAlarms() {
        alarms = CoinAlarmManager.shared.loadAlarms()
        tableView.reloadData()
    }

    @objc private func addAlarm() {
        let addVC = AddAlarmViewController()
        addVC.onAlarmAdded = { [weak self] in
            self?.loadAlarms()
        }
        navigationController?.pushViewController(addVC, animated: true)
    }

    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alarms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let alarm = alarms[indexPath.row]
        cell.textLabel?.text = "\(alarm.coin) - \(alarm.targetPrice) \(alarm.isHigher ? "↑" : "↓")"
        return cell
    }
}

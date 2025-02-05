//
//  SettingView.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import SnapKit

class SettingView: UIView {
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "앱 설정"
        label.textColor = UIColor(named: "TextColor")
        label.font = .extraLarge.bold()
        label.textAlignment = .center
        return label
    }()
    
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor(named: "BackgroundColor")
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
        return tableView
    }()
    
    var onItemSelected: ((Int) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor(named: "BackgroundColor")
        
        addSubview(titleLabel)
        addSubview(tableView)
        
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(10)
            make.centerX.equalToSuperview()
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

extension SettingView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell") ?? UITableViewCell(style: .default, reuseIdentifier: "SettingCell")
        let titles = ["알림 설정", "화면 모드 설정", "앱 정보"]
        cell.textLabel?.text = titles[indexPath.row]
        cell.textLabel?.font = .large.regular()
        cell.textLabel?.textColor = UIColor(named: "TextColor")
        cell.backgroundColor = UIColor(named: "BackgroundColor")
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onItemSelected?(indexPath.row)
    }
}

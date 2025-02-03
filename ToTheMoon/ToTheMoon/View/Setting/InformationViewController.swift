//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit

class InformationViewController: UIViewController {

    private let informationView = InformationView()
    private let data = ["현재 버전: 0.001", "최신 버전: 0.001"]

    override func loadView() {
        self.view = informationView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupActions()
        setupTableView()
        navigationController?.navigationBar.isHidden = true
    }

    private func setupActions() {
        informationView.backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }

    private func setupTableView() {
        informationView.tableView.delegate = self
        informationView.tableView.dataSource = self
    }

    @objc private func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
}

extension InformationViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InformationCell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.font = .large.regular()
        cell.textLabel?.textColor = UIColor(named: "TextColor")
        cell.backgroundColor = .clear

        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(named: "ContainerColor")
        backgroundView.layer.cornerRadius = 0
        if indexPath.row == 0 {
            backgroundView.layer.cornerRadius = 20
            backgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if indexPath.row == data.count - 1 {
            backgroundView.layer.cornerRadius = 20
            backgroundView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
        cell.backgroundView = backgroundView
        return cell
    }
}

extension InformationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == data.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: cell.bounds.width)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
    }
}

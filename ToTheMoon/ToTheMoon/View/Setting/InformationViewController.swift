//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit

class InformationViewController: UIViewController {

    private let informationView = InformationView()
    private let data = [
        "현재 버전: 0.001",
        "최신 버전: 0.001"
    ]

    override func loadView() {
        self.view = informationView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupActions()
        navigationController?.navigationBar.isHidden = true
    }

    private func setupActions() {
        informationView.backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
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
        cell.textLabel?.font = UIFont.systemFont(ofSize: 24)
        cell.textLabel?.textColor = .white
        cell.backgroundColor = UIColor(named: "ContainerColor")
        cell.layer.cornerRadius = 20
        cell.layer.masksToBounds = true
        return cell
    }
}

extension InformationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit

class ScreenModeViewController: UIViewController {
    
    private let screenModeView = ScreenModeView()
    private let options = ["기본값", "라이트 모드", "다크 모드"]
    private var selectedOptionIndex = 0
    
    override func loadView() {
        self.view = screenModeView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupActions()
        setupTableView()
        navigationController?.navigationBar.isHidden = true
        selectedOptionIndex = UserDefaults.standard.integer(forKey: "SelectedScreenMode")
    }
    
    private func setupActions() {
        screenModeView.backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
    
    private func setupTableView() {
        screenModeView.tableView.delegate = self
        screenModeView.tableView.dataSource = self
    }
    
    @objc private func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension ScreenModeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScreenModeCell", for: indexPath)
        cell.textLabel?.text = options[indexPath.row]
        cell.textLabel?.font = .large.regular()
        cell.textLabel?.textColor = UIColor(named: "TextColor")
        cell.backgroundColor = .clear
        
        cell.accessoryType = (indexPath.row == selectedOptionIndex) ? .checkmark : .none
        return cell
    }
}

extension ScreenModeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedOptionIndex = indexPath.row
        tableView.reloadData()
        print("선택된 화면 모드: \(options[selectedOptionIndex])")
        UserDefaults.standard.set(selectedOptionIndex, forKey: "SelectedScreenMode")
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            applyScreenMode(to: window, modeIndex: selectedOptionIndex)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == options.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: cell.bounds.width)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        }
    }
}

private func applyScreenMode(to window: UIWindow, modeIndex: Int) {
    switch modeIndex {
    case 1:
        window.overrideUserInterfaceStyle = .light
    case 2:
        window.overrideUserInterfaceStyle = .dark
    default:
        window.overrideUserInterfaceStyle = .unspecified
    }
}

func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 55
    
}


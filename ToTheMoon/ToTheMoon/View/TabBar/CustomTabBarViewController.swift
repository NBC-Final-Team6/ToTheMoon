//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit

class CustomTabBarViewController: UIViewController {
    private let customTabBar = CustomTabBarView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTabBarActions()
    }

    private func setupUI() {
        view.addSubview(customTabBar)
        customTabBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(80)
        }
    }

    private func setupTabBarActions() {
        customTabBar.onTabSelected = { [weak self] selectedIndex in
            self?.handleTabSelection(selectedIndex: selectedIndex)
        }
    }

    private func handleTabSelection(selectedIndex: Int) {
        print("Selected Tab: \(selectedIndex)")
        customTabBar.updateButtonSelection(selectedIndex: selectedIndex)
    }
}

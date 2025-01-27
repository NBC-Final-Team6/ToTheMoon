//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import SnapKit

class CustomTabBarViewController: UIViewController {
    private let customTabBar = CustomTabBarView()
    private let favoritesNavVC = UINavigationController(rootViewController: FavoritesViewController())
    private let coinPricesNavVC = UINavigationController(rootViewController: CoinPriceViewController())
    private let settingsNavVC = UINavigationController(rootViewController: SettingViewController())

    private var currentViewController: UIViewController?


    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTabBarActions()
        selectTab(at: 0)
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
        customTabBar.updateButtonSelection(selectedIndex: selectedIndex)
        selectTab(at: selectedIndex)
    }
    
    private func selectTab(at index: Int) {
        currentViewController?.view.removeFromSuperview()
        currentViewController?.removeFromParent()

        var selectedViewController: UIViewController?

        switch index {
        case 0:
            selectedViewController = favoritesNavVC
        case 1:
            selectedViewController = coinPricesNavVC
        case 2:
            selectedViewController = settingsNavVC
        default:
            break
        }

        if let selectedVC = selectedViewController {
            addChild(selectedVC)
            view.insertSubview(selectedVC.view, belowSubview: customTabBar)
            selectedVC.view.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.bottom.equalTo(customTabBar.snp.top)
            }
            currentViewController = selectedVC
        }
    }
}

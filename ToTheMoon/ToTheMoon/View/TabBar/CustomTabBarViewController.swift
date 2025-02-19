//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class CustomTabBarViewController: UIViewController {
    private let customTabBar = CustomTabBarView()
    private let coinPricesNavVC = UINavigationController(rootViewController: CoinPriceViewController())
    private let favoritesNavVC = UINavigationController(rootViewController: FavoritesContainerViewController())
    private let settingsNavVC = UINavigationController(rootViewController: SettingViewController())

    private var currentViewController: UIViewController?
    private let disposeBag = DisposeBag()


    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTabBarBinding()
        selectTab(at: 0)
        navigationController?.navigationBar.isHidden = true
    }

    private func setupUI() {
        let backgroundView = UIView()
        backgroundView.backgroundColor = .background
        view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(120)
        }

        
        view.addSubview(customTabBar)
        customTabBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(80)
        }
    }

    private func setupTabBarBinding() {
        customTabBar.selectedTab
            .subscribe(onNext: { [weak self] selectedIndex in
                self?.handleTabSelection(selectedIndex: selectedIndex)
            })
            .disposed(by: disposeBag)
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
            selectedViewController = coinPricesNavVC
        case 1:
            selectedViewController = favoritesNavVC
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

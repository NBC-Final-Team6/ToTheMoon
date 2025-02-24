//
//  SceneDelegate.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    let dummyMarketPrice = MarketPrice(
        symbol: "BTC",
        price: 50000.0,
        exchange: "Upbit",
        change: "RISE",
        changeRate: 0.05,
        quoteVolume: 120000000.0,
        highPrice: 52000.0,
        lowPrice: 48000.0,
        image: nil
    )
    
    lazy var dummyViewModel: AlarmEditViewModel = {
        return AlarmEditViewModel(selectedCoin: dummyMarketPrice)
    }()

    // Controller 생성
    lazy var alarmEditVC: AlarmEditViewController = {
        return AlarmEditViewController(viewModel: dummyViewModel)
    }()
    

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(rootViewController: CustomTabBarViewController())
        window.makeKeyAndVisible()
        self.window = window

        let selectedMode = UserDefaults.standard.integer(forKey: "SelectedScreenMode")
        applyScreenMode(to: window, modeIndex: selectedMode)
    }
    
    func applyScreenMode(to window: UIWindow, modeIndex: Int) {
        switch modeIndex {
        case 1:
            window.overrideUserInterfaceStyle = .light
        case 2:
            window.overrideUserInterfaceStyle = .dark
        default:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        
    }

    func sceneWillResignActive(_ scene: UIScene) {
        
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        
    }


}


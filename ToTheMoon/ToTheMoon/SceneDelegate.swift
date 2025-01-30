//
//  SceneDelegate.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        
        // 필요한 UseCase 인스턴스 생성
        let getMarketPricesUseCase = GetMarketPricesUseCase() // 실제 구현에 맞게 수정 필요
        let searchViewModel = SearchViewModel(getMarketPricesUseCase: getMarketPricesUseCase)
        let searchViewController = SearchViewController(viewModel: searchViewModel)
        
        window.rootViewController = UINavigationController(rootViewController: searchViewController)
        window.makeKeyAndVisible()
        self.window = window
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


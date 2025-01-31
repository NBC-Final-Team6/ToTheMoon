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
        
        let getMarketPricesUseCase = GetMarketPricesUseCase()
        let manageFavoritesUseCase = ManageFavoritesUseCase() // ManageFavoritesUseCaseProtocol 준수 객체
        
        let viewModel = SearchViewModel(
            getMarketPricesUseCase: getMarketPricesUseCase,
            manageFavoritesUseCase: manageFavoritesUseCase
        )
        
        let rootViewController = SearchViewController(viewModel: viewModel)
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(rootViewController: rootViewController)
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


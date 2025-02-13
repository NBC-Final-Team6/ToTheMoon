//
//  AppDelegate.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import RxSwift
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let disposeBag = DisposeBag()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        let up = UpbitWebSocketService()
//        up.fetchKrwTicker(for: "BTC" )
//            .subscribe(onNext: { marketPrices in
//                print("✅ btc 실시간 가격 업데이트: \(marketPrices)")
//            }, onError: { error in
//                print("❌ WebSocket 에러: \(error)")
//            })
//            .disposed(by: disposeBag)
//        
//        up.fetchKrwTicker(for: "XRP" )
//            .subscribe(onNext: { marketPrices in
//                print("✅ xrp 실시간 가격 업데이트: \(marketPrices)")
//            }, onError: { error in
//                print("❌ WebSocket 에러: \(error)")
//            })
//            .disposed(by: disposeBag)
//
        let coinoneService = CoinoneWebSocketService()

        let btcSubscription = coinoneService.fetchKrwTicker(for: "BTC")
            .subscribe(onNext: { marketPrice in
                print("📈 BTC 실시간 가격 업데이트: \(marketPrice.price)")
            }, onError: { error in
                print("❌ WebSocket BTC 에러: \(error)")
            })

        let xrpSubscription = coinoneService.fetchKrwTicker(for: "XRP")
            .subscribe(onNext: { marketPrice in
                print("📈 XRP 실시간 가격 업데이트: \(marketPrice.price)")
            }, onError: { error in
                print("❌ WebSocket XRP 에러: \(error)")
            })
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
}


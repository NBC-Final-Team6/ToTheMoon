//
//  AppDelegate.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import RxSwift
import Firebase
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Thread.sleep(forTimeInterval: 1.0)
        
        FirebaseApp.configure()
        
        if FirebaseApp.app() == nil {
            print("Firebase 초기화 실패!")
        } else {
            print("Firebase 초기화 완료")
        }
        
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self  // 푸시 알림을 받을 수 있도록 설정
        requestNotificationPermission()

        return true
    }
    
    // 알림 권한 요청 및 APNs 등록
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                print("푸시 알림 권한 허용됨")
            } else {
                print("알림 권한 거부됨")
            }
        }
    }
    
    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

    // APNs 토큰 등록 완료 후 FCM 토큰 가져오기
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs 토큰 등록 완료:", deviceToken)
        Messaging.messaging().apnsToken = deviceToken

        // APNs 등록 후 FCM 토큰 요청
        fetchFCMToken()
    }
}

// FCM 토큰 처리
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("FCM 토큰을 받을 수 없습니다.")
            return
        }
        print("FCM 토큰 수신:", fcmToken)
        UserDefaults.standard.set(fcmToken, forKey: "fcmToken") // 저장
    }

    // APNs 등록 후 FCM 토큰 가져오기 (기존 코드에서 이동)
    private func fetchFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("FCM 토큰 가져오기 실패:", error.localizedDescription)
            } else if let token = token {
                print("FCM 토큰 가져오기 성공:", token)
                UserDefaults.standard.set(token, forKey: "fcmToken")  // 저장
            }
        }
    }
}

// 푸시 알림 처리
extension AppDelegate {
    // 🔹 앱이 실행 중일 때도 푸시 알림 표시
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("[푸시 알림 수신] 앱이 실행 중일 때도 알림 표시됨")
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge]) // iOS 14 이상 대응 (banner)
        } else {
            completionHandler([.alert, .sound, .badge]) // iOS 14 미만 대응
        }
    }

    // 푸시 알림 클릭 시 이벤트 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("[푸시 알림 클릭] \(userInfo)")
        completionHandler()
    }
}

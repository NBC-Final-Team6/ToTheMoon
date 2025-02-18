//
//  NotificationSettingViewModel.swift
//  ToTheMoon
//
//  Created by t2023-m0149 on 2/14/25.
//

import Foundation
import RxSwift
import RxCocoa

class NotificationSettingViewModel {
    let options = BehaviorRelay<[String]>(value: ["소리만", "소리와 진동", "진동", "무음"])
    
    let notificationEnabled = BehaviorRelay<Bool>(value: UserDefaults.standard.bool(forKey: "NotificationEnabled"))
    
    let selectedOptionIndex = BehaviorRelay<Int>(value: UserDefaults.standard.integer(forKey: "SelectedNotificationStyle"))
    
    private let disposeBag = DisposeBag()
    
    init() {
        notificationEnabled
            .distinctUntilChanged()
            .bind { isOn in
                UserDefaults.standard.set(isOn, forKey: "NotificationEnabled")
            }
            .disposed(by: disposeBag)
        
        selectedOptionIndex
            .distinctUntilChanged()
            .bind { index in
                UserDefaults.standard.set(index, forKey: "SelectedNotificationStyle")
            }
            .disposed(by: disposeBag)
    }
}

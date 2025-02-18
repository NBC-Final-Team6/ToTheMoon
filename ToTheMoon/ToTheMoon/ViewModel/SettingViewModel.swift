//
//  SettingViewModel.swift
//  ToTheMoon
//
//  Created by t2023-m0149 on 2/14/25.
//

import Foundation
import RxSwift
import RxCocoa

class SettingViewModel {
    let settings = Observable.just(["알림 설정", "화면 모드 설정", "앱 정보"])
    
    let selectedItem = PublishSubject<Int>()
}

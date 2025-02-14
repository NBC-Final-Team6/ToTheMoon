//
//  ScreenViewModel.swift
//  ToTheMoon
//
//  Created by t2023-m0149 on 2/14/25.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa


class ScreenModeViewModel {
    let options = BehaviorRelay<[String]>(value: ["기본값", "라이트 모드", "다크 모드"])
    
    let selectedOptionIndex = BehaviorRelay<Int>(value: UserDefaults.standard.integer(forKey: "SelectedScreenMode"))
    
    private let disposeBag = DisposeBag()
    
    init() {
        selectedOptionIndex
            .subscribe(onNext: { index in
                UserDefaults.standard.set(index, forKey: "SelectedScreenMode")
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    self.applyScreenMode(to: window, modeIndex: index)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func saveSelectedOption() {
        UserDefaults.standard.set(selectedOptionIndex.value, forKey: "SelectedScreenMode")
    }

    
    public func applyScreenMode(to window: UIWindow, modeIndex: Int) {
        switch modeIndex {
        case 1:
            window.overrideUserInterfaceStyle = .light
        case 2:
            window.overrideUserInterfaceStyle = .dark
        default:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
}

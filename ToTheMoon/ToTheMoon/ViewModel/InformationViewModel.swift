//
//  InformationViewModel.swift
//  ToTheMoon
//
//  Created by t2023-m0149 on 2/14/25.
//

import RxSwift
import RxCocoa

class InformationViewModel {
    let data = BehaviorRelay<[String]>(value: ["현재 버전: 1.1.1", "최신 버전: 1.1.1"])
}

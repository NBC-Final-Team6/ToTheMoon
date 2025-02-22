//
//  AlarmEditViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/22/25.
//

import Foundation
import RxSwift
import RxCocoa

final class AlarmEditViewModel {
    
    // Input
    struct Input {
        let exchange = BehaviorSubject<String>(value: "")
        let coin = BehaviorSubject<String>(value: "")
        let price = BehaviorSubject<Double>(value: 0.0)
        let condition = BehaviorSubject<String>(value: "above") // 기본값 "above"
        let submitTrigger = PublishSubject<Void>()
    }
    
    // Output
    struct Output {
        let alertRegistrationResult = PublishSubject<Result<String, Error>>()
    }
    
    // Input/Output 인스턴스
    let input = Input()
    let output = Output()
    
    private let disposeBag = DisposeBag()
    
    init() {
        // submitTrigger가 발생하면 네트워크 요청 실행
        input.submitTrigger
            .withLatestFrom(Observable.combineLatest(input.exchange, input.coin, input.price, input.condition))
            .flatMapLatest { [weak self] exchange, coin, price, condition -> Observable<Result<String, Error>> in
                guard let self = self else { return Observable.just(.failure(NSError(domain: "ViewModel Error", code: 0, userInfo: nil))) }
                
                guard let fcmToken = UserDefaults.standard.string(forKey: "fcmToken") else {
                    return Observable.just(.failure(NSError(domain: "FCM Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "❌ FCM 토큰 없음"])))
                }
                
                return PriceAlertManager.shared.registerPriceAlert(exchange: exchange, coin: coin, price: price, condition: condition, fcmToken: fcmToken)
            }
            .bind(to: output.alertRegistrationResult)
            .disposed(by: disposeBag)
    }
}

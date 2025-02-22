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
        let exchange = BehaviorRelay<String>(value: "")
        let coin = BehaviorRelay<String>(value: "")
        let price = BehaviorRelay<Double>(value: 0.0)
        let condition = BehaviorRelay<String>(value: "above") // 기본값 "above"
        let submitTrigger = PublishRelay<Void>() // 비동기 트리거 (이벤트 발생)
    }
    
    // Output
    struct Output {
        let alertRegistrationResult = PublishRelay<Result<String, Error>>() // 에러가 없는 PublishRelay
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
                guard let self = self else {
                    return Observable.just(.failure(NSError(domain: "ViewModel Error", code: 0, userInfo: nil)))
                }
                
                guard let fcmToken = UserDefaults.standard.string(forKey: "fcmToken") else {
                    return Observable.just(.failure(NSError(domain: "FCM Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "❌ FCM 토큰 없음"])))
                }
                
                let alert = PriceAlert(exchange: exchange, coin: coin, price: price, condition: condition, fcmToken: fcmToken)
                
                return PriceAlertManager.shared.registerPriceAlert(alert: alert)
            }
            .bind(to: output.alertRegistrationResult)
            .disposed(by: disposeBag)
    }
}

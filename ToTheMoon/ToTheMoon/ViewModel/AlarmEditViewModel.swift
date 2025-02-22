//
//  AlarmEditViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/22/25.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

final class AlarmEditViewModel {
    
    private let disposeBag = DisposeBag()
    
    // Input
    struct Input {
        let marketPrice: BehaviorRelay<MarketPrice?>
        let condition: BehaviorRelay<String>
        let submitTrigger: PublishRelay<Void>
        
        init(selectedCoin: MarketPrice) {
            self.marketPrice = BehaviorRelay(value: selectedCoin)
            self.condition = BehaviorRelay(value: "above") // 기본값 "above"
            self.submitTrigger = PublishRelay()
        }
    }
    
    // Output
    struct Output {
        let alertRegistrationResult: PublishRelay<Result<String, Error>>
        let selectedCoinRelay: BehaviorRelay<MarketPrice>
        
        init(selectedCoin: MarketPrice) {
            self.alertRegistrationResult = PublishRelay()
            self.selectedCoinRelay = BehaviorRelay(value: selectedCoin)
        }
    }
    
    // Input/Output 인스턴스
    let input: Input
    let output: Output
    
    init(selectedCoin: MarketPrice) {
        self.input = Input(selectedCoin: selectedCoin)
        self.output = Output(selectedCoin: selectedCoin)
        
        // submitTrigger가 발생하면 네트워크 요청 실행
        input.submitTrigger
            .withLatestFrom(Observable.combineLatest(input.marketPrice.compactMap { $0 }, input.condition))
            .flatMapLatest { [weak self] marketPrice, condition -> Observable<Result<String, Error>> in
                guard let self = self else {
                    return Observable.just(.failure(NSError(domain: "ViewModel Error", code: 0, userInfo: nil)))
                }
                
                guard let fcmToken = UserDefaults.standard.string(forKey: "fcmToken") else {
                    return Observable.just(.failure(NSError(domain: "FCM Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "❌ FCM 토큰 없음"])))
                }
                
                let alert = PriceAlert(
                    exchange: marketPrice.exchange,
                    coin: marketPrice.symbol,
                    price: marketPrice.price,
                    condition: condition,
                    fcmToken: fcmToken
                )
                
                return PriceAlertManager.shared.registerPriceAlert(alert: alert)
            }
            .bind(to: output.alertRegistrationResult)
            .disposed(by: disposeBag)
    }
}

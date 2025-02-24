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
        let deleteTrigger: PublishRelay<String>
        let pushNotificationReceived: PublishRelay<String> // ✅ 푸시 알림 도착 이벤트 추가
        
        init(selectedCoin: MarketPrice) {
            self.marketPrice = BehaviorRelay(value: selectedCoin)
            self.condition = BehaviorRelay(value: "above") // 기본값 "above"
            self.submitTrigger = PublishRelay()
            self.deleteTrigger = PublishRelay()
            self.pushNotificationReceived = PublishRelay() // ✅ 추가
        }
    }
    
    // Output
    struct Output {
        let alertRegistrationResult: PublishRelay<Result<String, Error>>
        let alertDeletionResult: PublishRelay<Result<String, Error>>
        let selectedCoinRelay: BehaviorRelay<MarketPrice>
        let alertHistoryRelay: BehaviorRelay<[PriceAlertWithID]> // ✅ ID 포함된 알림
        
        init(selectedCoin: MarketPrice) {
            self.alertRegistrationResult = PublishRelay()
            self.alertDeletionResult = PublishRelay()
            self.selectedCoinRelay = BehaviorRelay(value: selectedCoin)
            self.alertHistoryRelay = BehaviorRelay(value: [])
        }
    }
    
    let input: Input
    let output: Output
    
    init(selectedCoin: MarketPrice) {
        self.input = Input(selectedCoin: selectedCoin)
        self.output = Output(selectedCoin: selectedCoin)
        
        // 앱 실행 시 저장된 알림 불러오기
        fetchSavedAlerts()
        
        // 🔔 푸시 알림 도착 시 해당 알림 자동 삭제
        input.pushNotificationReceived
            .subscribe(onNext: { [weak self] alertID in
                self?.removeAlert(alertID)
            })
            .disposed(by: disposeBag)
        
        // 알림 삭제 처리
        input.deleteTrigger
            .flatMapLatest { [weak self] alertID -> Observable<Result<String, Error>> in
                guard let self = self else {
                    return Observable.just(.failure(NSError(domain: "ViewModel Error", code: 0, userInfo: nil)))
                }
                
                return PriceAlertManager.shared.deletePriceAlert(alertID: alertID)
                    .do(onNext: { result in
                        if case .success(_) = result {
                            self.removeAlert(alertID) // UserDefaults에서 삭제
                        }
                    })
            }
            .bind(to: output.alertDeletionResult)
            .disposed(by: disposeBag)
    }
    
    private let userDefaultsKey = "savedAlerts"
    
    /// 📥 **서버에서 알림 가져오기 (앱 실행 시 호출)**
        func fetchSavedAlerts() {
            PriceAlertManager.shared.fetchPriceAlerts()
                .subscribe(onNext: { [weak self] result in
                    switch result {
                    case .success(let alerts):
                        self?.output.alertHistoryRelay.accept(alerts) // ✅ UI 업데이트
                    case .failure(let error):
                        print("❌ 알림 불러오기 실패:", error.localizedDescription)
                    }
                })
                .disposed(by: disposeBag)
        }
        
        /// ❌ **특정 알림 삭제 (UI & UserDefaults 업데이트)**
        func removeAlert(_ alertID: String) {
            var alerts = output.alertHistoryRelay.value
            alerts.removeAll { $0.id == alertID } // ID 기반 삭제
            
            output.alertHistoryRelay.accept(alerts) // ✅ UI 업데이트
        }
}

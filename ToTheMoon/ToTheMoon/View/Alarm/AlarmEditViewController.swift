//
//  AlarmEditViewController.swift
//  ToTheMoon
//
//  Created by Jimin on 2/20/25.
//

import UIKit
import RxSwift

class AlarmEditViewController: UIViewController {
    
    private let alarmEditView = AlarmEditView()
    private let disposeBag = DisposeBag()
    private let viewModel: AlarmEditViewModel
    
    init(viewModel: AlarmEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = alarmEditView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTapGesture()
        setupBindings()
        setupEventHandlers()
        
        // 푸시 알림 도착 감지 (자동 삭제)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePushNotification(_:)),
            name: NSNotification.Name("PriceAlertTriggered"),
            object: nil
        )
    }
    
    // MARK: - Rx 바인딩 설정
    private func setupBindings() {
        // 선택한 코인의 가격 정보 업데이트
        viewModel.output.selectedCoinRelay
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] marketPrice in
                self?.updateUI(with: marketPrice)
            })
            .disposed(by: disposeBag)
        
        // 가격 입력값을 ViewModel에 반영
        alarmEditView.priceTextField.rx.text.orEmpty
            .map { $0.replacingOccurrences(of: ",", with: "") }
            .compactMap(Double.init)
            .subscribe(onNext: { [weak self] price in
                guard let self = self else { return }
                var updatedMarketPrice = self.viewModel.input.marketPrice.value
                updatedMarketPrice?.price = price
                self.viewModel.input.marketPrice.accept(updatedMarketPrice)
            })
            .disposed(by: disposeBag)
        
        // 조건(이상/이하) 선택 반영
        alarmEditView.percentageSignSegment.rx.selectedSegmentIndex
            .map { $0 == 0 ? "above" : "below" }
            .bind(to: viewModel.input.condition)
            .disposed(by: disposeBag)
        
        // 알림 추가 버튼 클릭 이벤트 바인딩
        alarmEditView.addAlertButton.rx.tap
            .bind(to: viewModel.input.submitTrigger)
            .disposed(by: disposeBag)
        
        // 서버 응답 결과 처리
        viewModel.output.alertRegistrationResult
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { result in
                switch result {
                case .success(let message):
                    print("✅ 알림 등록 성공: \(message)")
                case .failure(let error):
                    print("❌ 알림 등록 실패: \(error.localizedDescription)")
                }
            })
            .disposed(by: disposeBag)
        
        // alertHistoryRelay가 PriceAlertWithID 배열을 받도록 수정
        viewModel.output.alertHistoryRelay
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] alertHistory in
                self?.alarmEditView.updateAlertHistory(with: alertHistory)
            })
            .disposed(by: disposeBag)
    }
    
    private func updateUI(with marketPrice: MarketPrice) {
        alarmEditView.coinNameLabel.text = "\(marketPrice.symbol) (\(marketPrice.exchange))"
        alarmEditView.currentPriceLabel.text = "\(Int(marketPrice.price)) 원"

        let formattedHighLow = "\(Int(marketPrice.highPrice)) / \(Int(marketPrice.lowPrice))"
        alarmEditView.dayRangeLabel.text = formattedHighLow

        let changeText = "\(marketPrice.changeRate)%"
        alarmEditView.priceChangeLabel.text = changeText
        alarmEditView.priceChangeLabel.textColor = marketPrice.change == "RISE" ? .numbersGreen : .numbersRed

        alarmEditView.priceTextField.text = "\(Int(marketPrice.price))"
    }
    
    // MARK: - 이벤트 핸들러 설정
    private func setupEventHandlers() {
        // X 버튼 클릭 시 알림 삭제
        alarmEditView.onDeleteAlert = { [weak self] alertID in
            self?.deleteAlert(alertID)
        }
        
        // NotificationCenter를 이용한 알림 목록 갱신
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshAlertHistory),
            name: NSNotification.Name("AlertDeleted"),
            object: nil
        )
    }
    
    // MARK: - 푸시 알림 도착 시 알림 자동 삭제
    @objc private func handlePushNotification(_ notification: Notification) {
        if let alertID = notification.object as? String {
            print("📌 푸시 알림 도착 - ID:", alertID)
            viewModel.input.pushNotificationReceived.accept(alertID)
        }
    }
    
    // MARK: - 알림 삭제 처리
    private func deleteAlert(_ alertID: String) {
        viewModel.input.deleteTrigger.accept(alertID)
    }
    
    // MARK: - 알림 목록 갱신
    @objc private func refreshAlertHistory() {
        viewModel.fetchSavedAlerts()
    }
    
    // MARK: - 네비게이션 바 설정
    private func setupNavigationBar() {
        title = "알림 편집"
        
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = .text
        navigationItem.leftBarButtonItem = backButton
        
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.large.bold(),
            NSAttributedString.Key.foregroundColor: UIColor.text
        ]
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - 화면 터치 시 키보드 및 드롭다운 닫기
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutside))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTapOutside(gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if let dropdownView = view.subviews.first(where: { $0 is UITableView }),
           !dropdownView.frame.contains(location) {
            alarmEditView.dismissDropdownIfNeeded()
        }
    }
}

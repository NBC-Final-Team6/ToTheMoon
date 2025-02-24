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
    }
    
    private func setupBindings() {
        // `selectedCoinRelay`의 변경을 감지하고 UI 업데이트
        viewModel.output.selectedCoinRelay
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] marketPrice in
                self?.updateUI(with: marketPrice)
            })
            .disposed(by: disposeBag)
        
        // `priceTextField` 값 변경을 `marketPrice.price`로 반영
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
        
        // 가격 지정 + 버튼
        alarmEditView.increaseButton.rx.tap
            .withLatestFrom(viewModel.output.selectedCoinRelay)
            .withLatestFrom(alarmEditView.priceTextField.rx.text.orEmpty) { (marketPrice, priceText) -> (Double, String) in
                return (marketPrice.price, priceText)
            }
            .subscribe(onNext: { [weak self] marketPrice, priceText in
                guard let self = self else { return }
                let priceDigits = priceText.replacingOccurrences(of: ",", with: "")
                if let currentPrice = Double(priceDigits) {
                    let onePercent = marketPrice * 0.01
                    let newPrice = currentPrice + onePercent
                    
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .decimal
                    formatter.maximumFractionDigits = 0
                    
                    if let formattedPrice = formatter.string(from: NSNumber(value: newPrice)) {
                        self.alarmEditView.priceTextField.text = formattedPrice
                    }
                }
            })
            .disposed(by: disposeBag)

        // 가격 지정 - 버튼
        alarmEditView.decreaseButton.rx.tap
            .withLatestFrom(viewModel.output.selectedCoinRelay)
            .withLatestFrom(alarmEditView.priceTextField.rx.text.orEmpty) { (marketPrice, priceText) -> (Double, String) in
                return (marketPrice.price, priceText)
            }
            .subscribe(onNext: { [weak self] marketPrice, priceText in
                guard let self = self else { return }
                let priceDigits = priceText.replacingOccurrences(of: ",", with: "")
                if let currentPrice = Double(priceDigits) {
                    let onePercent = marketPrice * 0.01
                    let newPrice = currentPrice - onePercent
                    
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .decimal
                    formatter.maximumFractionDigits = 0
                    
                    if let formattedPrice = formatter.string(from: NSNumber(value: newPrice)) {
                        self.alarmEditView.priceTextField.text = formattedPrice
                    }
                }
            })
            .disposed(by: disposeBag)

        
        // `percentageSignSegment` 값 변경을 `condition`에 반영
        alarmEditView.percentageSignSegment.rx.selectedSegmentIndex
            .map { $0 == 0 ? "above" : "below" }
            .bind(to: viewModel.input.condition)
            .disposed(by: disposeBag)
        
        // `addAlertButton` 클릭 시 서버에 알림 요청
        alarmEditView.addAlertButton.rx.tap
            .do(onNext: { print("addAlertButton tapped!") }) // 로그 추가
            .bind(to: viewModel.input.submitTrigger)
            .disposed(by: disposeBag)
        
        // 서버 응답 UI 처리
        viewModel.output.alertRegistrationResult
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { result in
                switch result {
                case .success(let message):
                    print("\(message)")
                    // 성공 알림 UI 업데이트 가능
                case .failure(let error):
                    print("오류 발생: \(error.localizedDescription)")
                }
            })
            .disposed(by: disposeBag)
    }
    
    ///  UI 업데이트 메서드
    private func updateUI(with marketPrice: MarketPrice) {
        alarmEditView.coinNameLabel.text = "\(marketPrice.symbol) (\(marketPrice.exchange))"
        
        // 천 단위 구분자를 위한 NumberFormatter 생성
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        // 현재가에 천 단위 구분자 추가
        let priceString = formatter.string(from: NSNumber(value: marketPrice.price)) ?? "0"
        alarmEditView.currentPriceLabel.text = "\(priceString) 원"
        
        // 24시 최고/최저에 천 단위 구분자 추가
        let highPriceString = formatter.string(from: NSNumber(value: marketPrice.highPrice)) ?? "0"
        let lowPriceString = formatter.string(from: NSNumber(value: marketPrice.lowPrice)) ?? "0"
        let formattedHighLow = "\(highPriceString) / \(lowPriceString)"
        alarmEditView.dayRangeLabel.text = formattedHighLow
        
        // 가격 변화율 표시
        let changeText = "\(marketPrice.changeRate)%"
        alarmEditView.priceChangeLabel.text = changeText
        alarmEditView.priceChangeLabel.textColor = marketPrice.change == "RISE" ? .numbersGreen : .numbersRed
        
        // 가격 지정 필드에 천 단위 구분자 추가
        let initialPriceString = formatter.string(from: NSNumber(value: Int(marketPrice.price))) ?? "0"
        alarmEditView.priceTextField.text = initialPriceString
        
        // 코인 이미지 설정
//        if let image = marketPrice.image {
//            alarmEditView.coinImageView.image = image
//        }
    }
    
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
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutside))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTapOutside(gesture: UITapGestureRecognizer) {
        guard let alarmEditView = view as? AlarmEditView else { return }
        
        let location = gesture.location(in: view)
        if let dropdownView = view.subviews.first(where: { $0 is UITableView }),
           !dropdownView.frame.contains(location) {
            // 드롭다운 영역 외부를 탭한 경우에만 닫기
            alarmEditView.dismissDropdownIfNeeded()
        }
    }
}

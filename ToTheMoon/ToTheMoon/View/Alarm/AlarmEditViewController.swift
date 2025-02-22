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
    
    func setupBindings() {
        // Input 바인딩 (UI 값 → ViewModel)
        alarmEditView.priceTextField.rx.text.orEmpty
            .map { $0.replacingOccurrences(of: ",", with: "") }
            .compactMap(Double.init)
            .bind(to: viewModel.input.price)
            .disposed(by: disposeBag)
        
        alarmEditView.percentageSignSegment.rx.selectedSegmentIndex
            .map { $0 == 0 ? "above" : "below" }
            .bind(to: viewModel.input.condition)
            .disposed(by: disposeBag)
        
        alarmEditView.addAlertButton.rx.tap
            .bind(to: viewModel.input.submitTrigger)
            .disposed(by: disposeBag)
        
        // Output 구독 (서버 응답 → UI 업데이트)
        viewModel.output.alertRegistrationResult
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { result in
                switch result {
                case .success(let message):
                    print(message)
                    // 성공 알림 표시
                case .failure(let error):
                    print("오류 발생: \(error.localizedDescription)")
                }
            })
            .disposed(by: disposeBag)
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

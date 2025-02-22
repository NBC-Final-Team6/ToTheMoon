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
    
    override func loadView() {
        view = alarmEditView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTapGesture()
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

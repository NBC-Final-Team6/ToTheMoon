//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import RxSwift
import RxCocoa

class NotificationSettingViewController: UIViewController {
    
    private let notificationView = NotificationSettingView()
    private let viewModel = NotificationSettingViewModel()
    private let disposeBag = DisposeBag()
    
    override func loadView() {
        self.view = notificationView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        navigationController?.navigationBar.isHidden = true
        
        notificationView.tableView.estimatedRowHeight = 0
        notificationView.tableView.rowHeight = 55
    }
    
    private func bindViewModel() {
        viewModel.options
            .bind(to: notificationView.tableView.rx.items(cellIdentifier: "NotificationStyleCell")) { index, title, cell in
                cell.textLabel?.text = title
                cell.textLabel?.font = .large.regular()
                cell.textLabel?.textColor = UIColor(named: "TextColor")
                cell.backgroundColor = .clear
                cell.accessoryType = (index == self.viewModel.selectedOptionIndex.value) ? .checkmark : .none
                cell.tintColor = .personel
                
                cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
                cell.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
                
                
                if index == self.viewModel.options.value.count - 1 {
                    cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: -1, right: cell.bounds.width)
                }
            }
            .disposed(by: disposeBag)
        
        notificationView.tableView.rx.itemSelected
            .map { $0.row }
            .bind(to: viewModel.selectedOptionIndex)
            .disposed(by: disposeBag)
        
        viewModel.selectedOptionIndex
            .subscribe(onNext: { [weak self] selectedIndex in
                guard let self = self else { return }
                self.notificationView.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        notificationView.notificationSwitch.rx.isOn
            .bind(to: viewModel.notificationEnabled)
            .disposed(by: disposeBag)
        
        viewModel.notificationEnabled
            .bind(to: notificationView.notificationSwitch.rx.isOn)
            .disposed(by: disposeBag)
        
        notificationView.backButton.rx.tap
            .bind { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
        
        notificationView.tableView.rx.willDisplayCell
            .subscribe(onNext: { [weak self] cell, indexPath in
                guard let self = self else { return }
                let isLastCell = indexPath.row == self.viewModel.options.value.count - 1
                cell.separatorInset = isLastCell ? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: cell.bounds.width) : UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            })
            .disposed(by: disposeBag)
    }
}

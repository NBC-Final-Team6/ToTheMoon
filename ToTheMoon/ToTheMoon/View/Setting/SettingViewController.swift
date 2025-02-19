//
//  SettingViewController.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import RxSwift
import RxCocoa

class SettingViewController: UIViewController {
    
    private let settingView = SettingView()
    private let viewModel = SettingViewModel()
    private let disposeBag = DisposeBag()
    
    override func loadView() {
        self.view = settingView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        navigationController?.navigationBar.isHidden = true
    }
    
    private func bindViewModel() {
        viewModel.settings
            .bind(to: settingView.tableView.rx.items(cellIdentifier: "SettingCell")) { index, title, cell in
                cell.textLabel?.text = title
                cell.textLabel?.font = .large.regular()
                cell.textLabel?.textColor = UIColor(named: "TextColor")
                cell.backgroundColor = UIColor(named: "BackgroundColor")
                cell.accessoryType = .disclosureIndicator
                
                let selectedBackgroundView = UIView()
                selectedBackgroundView.backgroundColor = UIColor.lightGray
                cell.selectedBackgroundView = selectedBackgroundView
            }
            .disposed(by: disposeBag)
        
        settingView.tableView.rx.willDisplayCell
            .subscribe(onNext: { cell, _ in
                cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
                cell.layoutMargins = .zero
            })
            .disposed(by: disposeBag)
        
        
        settingView.tableView.rx.itemSelected
            .map { $0.row }
            .bind(to: viewModel.selectedItem)
            .disposed(by: disposeBag)
        
        viewModel.selectedItem
            .subscribe(onNext: { [weak self] row in
                guard let self = self else { return }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    let indexPath = IndexPath(row: row, section: 0)
                    self.settingView.tableView.deselectRow(at: indexPath, animated: true)
                }
                
                let viewController: UIViewController
                switch row {
                case 0:
                    viewController = NotificationSettingViewController()
                case 1:
                    viewController = ScreenModeViewController()
                case 2:
                    viewController = InformationViewController()
                default:
                    return
                }
                self.navigationController?.pushViewController(viewController, animated: true)
            })
            .disposed(by: disposeBag)
    }
}



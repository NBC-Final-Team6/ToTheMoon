//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class ScreenModeViewController: UIViewController {
    
    private let screenModeView = ScreenModeView()
    private let viewModel = ScreenModeViewModel()
    private let disposeBag = DisposeBag()
    
    override func loadView() {
        self.view = screenModeView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        navigationController?.navigationBar.isHidden = true
        
        screenModeView.tableView.estimatedRowHeight = 0
        screenModeView.tableView.rowHeight = 55
    }
    
    private func bindViewModel() {
        viewModel.options
            .bind(to: screenModeView.tableView.rx.items(cellIdentifier: "ScreenModeCell")) { index, title, cell in
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
        
        screenModeView.tableView.rx.itemSelected
            .map { $0.row }
            .bind(to: viewModel.selectedOptionIndex)
            .disposed(by: disposeBag)
        
        viewModel.selectedOptionIndex
            .subscribe(onNext: { [weak self] selectedIndex in
                guard let self = self else { return }
                self.screenModeView.tableView.reloadData()
                self.viewModel.saveSelectedOption()
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    self.viewModel.applyScreenMode(to: window, modeIndex: selectedIndex)
                }
            })
            .disposed(by: disposeBag)
        
        screenModeView.backButton.rx.tap
            .bind { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
        
        screenModeView.tableView.rx.willDisplayCell
            .subscribe(onNext: { [weak self] cell, indexPath in
                guard let self = self else { return }
                let isLastCell = indexPath.row == self.viewModel.options.value.count - 1
                cell.separatorInset = isLastCell ? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: cell.bounds.width) : UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            })
            .disposed(by: disposeBag)
    }
}

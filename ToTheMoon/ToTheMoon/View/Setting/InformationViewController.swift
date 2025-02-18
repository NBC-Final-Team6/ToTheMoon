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

class InformationViewController: UIViewController {
    
    private let informationView = InformationView()
    private let viewModel = InformationViewModel()
    private let disposeBag = DisposeBag()
    
    override func loadView() {
        self.view = informationView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        navigationController?.navigationBar.isHidden = true
        
        informationView.tableView.estimatedRowHeight = 0
        informationView.tableView.rowHeight = 55
    }
    
    private func bindViewModel() {
        viewModel.data
            .bind(to: informationView.tableView.rx.items(cellIdentifier: "InformationCell")) { index, text, cell in
                cell.textLabel?.text = text
                cell.textLabel?.font = .large.regular()
                cell.textLabel?.textColor = UIColor(named: "TextColor")
                cell.backgroundColor = .clear
                cell.textLabel?.textAlignment = .left
                
                cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
                cell.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
                
                if index == self.viewModel.data.value.count - 1 {
                    cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: -1, right: cell.bounds.width)
                }
            }
            .disposed(by: disposeBag)
        
        informationView.backButton.rx.tap
            .bind { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
        
        informationView.tableView.rx.willDisplayCell
            .subscribe(onNext: { [weak self] cell, indexPath in
                guard let self = self else { return }
                let isLastCell = indexPath.row == self.viewModel.data.value.count - 1
                cell.separatorInset = isLastCell ? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: cell.bounds.width) : UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            })
            .disposed(by: disposeBag)
    }
}

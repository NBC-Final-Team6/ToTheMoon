//
//  CoinPriceViewController.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import RxSwift
import RxCocoa

class CoinPriceViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    private let viewModel = CoinPriceViewModel()
    
    private let coinPriceView = CoinPriceView()
    
    override func loadView() {
        view = coinPriceView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        coinPriceView.coinPriceTableView.delegate = self
        
        // 데이터 바인딩
        viewModel.coinPrices
            .bind(to: coinPriceView.coinPriceTableView.rx.items(cellIdentifier: CoinPriceTableViewCell.identifier, cellType: CoinPriceTableViewCell.self)) { (row, coinPrice, cell) in
                cell.configure(with: coinPrice)
            }
            .disposed(by: disposeBag)
        
        // 셀 선택 처리
        coinPriceView.coinPriceTableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.viewModel.selectCoinPrice(at: indexPath.row)
                self?.coinPriceView.coinPriceTableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
        
        // 선택된 코인의 차트 화면으로 네비게이션
        viewModel.selectedCoinPrice
            .subscribe(onNext: { [weak self] coinPrice in
                let chartVC = ChartViewController()
                self?.navigationController?.pushViewController(chartVC, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
}

extension CoinPriceViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

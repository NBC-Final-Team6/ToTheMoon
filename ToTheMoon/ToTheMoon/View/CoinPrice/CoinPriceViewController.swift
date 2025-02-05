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
        setupSwipeGestures()
        setupBinding()
        coinPriceView.coinPriceTableView.rx.setDelegate(self).disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    private func setupSwipeGestures() {
        // 왼쪽으로 스와이프 (다음 거래소)
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        leftSwipe.direction = .left
        view.addGestureRecognizer(leftSwipe)
        
        // 오른쪽으로 스와이프 (이전 거래소)
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        rightSwipe.direction = .right
        view.addGestureRecognizer(rightSwipe)
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        let exchanges: [Exchange] = [.upbit, .bithumb, .coinone, .korbit]
        let currentIndex = exchanges.firstIndex(of: viewModel.currentExchange) ?? 0
        
        var nextIndex: Int
        
        switch gesture.direction {
        case .left:  // 다음 거래소
            nextIndex = (currentIndex + 1) % exchanges.count
        case .right:  // 이전 거래소
            nextIndex = (currentIndex - 1 + exchanges.count) % exchanges.count
        default:
            return
        }
        
        // 마켓뷰 상태 초기화
        coinPriceView.resetMarketViews()
        coinPriceView.scrollToTop()
        
        // 다음 거래소로 변경
        viewModel.selectExchange(exchanges[nextIndex])
        
        // 해당하는 마켓뷰 강조 표시
        let marketViews = coinPriceView.getMarketViews()
        if nextIndex < marketViews.count {
            marketViews[nextIndex].handleTap()
        }
    }
    
    private func setupBinding() {
        // 테이블뷰 데이터 바인딩과 candles 데이터를 결합
        Observable
            .combineLatest(viewModel.coinPrices, viewModel.candlesDict)
            .observe(on: MainScheduler.instance)
            .map { coinPrices, candlesDict in
                return coinPrices.map { price in
                    let candles = candlesDict[price.symbol] ?? []
                    return (price, candles)
                }
            }
            .bind(to: coinPriceView.coinPriceTableView.rx.items(
                cellIdentifier: CoinPriceTableViewCell.identifier,
                cellType: CoinPriceTableViewCell.self)
            ) { row, element, cell in
                let (price, candles) = element
                cell.configure(with: price, candles: candles)
            }
            .disposed(by: disposeBag)
        
        // candles 데이터가 업데이트될 때마다 테이블뷰 리로드
        viewModel.candles
            .subscribe(onNext: { [weak self] _ in
                self?.coinPriceView.coinPriceTableView.reloadData()
            })
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
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] coinPrice in
                guard let self = self else { return }
                let exchange = self.viewModel.currentExchange // 현재 선택된 거래소
                let chartViewModel = ChartViewModel(exchange: exchange, selectedCoins: [coinPrice])
                let chartVC = ChartViewController(viewModel: chartViewModel, coinPriceViewModel: self.viewModel)
                self.navigationController?.pushViewController(chartVC, animated: true)
            })
            .disposed(by: disposeBag)
        
        // 거래소 선택 이벤트 처리
        for subview in coinPriceView.getMarketViews() {
            subview.selectedExchange
                .subscribe(onNext: { [weak self] exchange in
                    self?.coinPriceView.resetMarketViews()
                    self?.coinPriceView.scrollToTop()
                    self?.viewModel.selectExchange(exchange)
                })
                .disposed(by: disposeBag)
        }
        
        // 에러 처리
        viewModel.error
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { error in
//                print("Error occurred: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
}

extension CoinPriceViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}



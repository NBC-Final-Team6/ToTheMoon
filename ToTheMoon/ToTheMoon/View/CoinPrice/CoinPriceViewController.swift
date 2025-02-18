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
    private let viewModel: CoinPriceViewModelType
    private let coinPriceView: CoinPriceView
    
    init(viewModel: CoinPriceViewModelType = CoinPriceViewModel(),
         coinPriceView: CoinPriceView = CoinPriceView()) {
        self.viewModel = viewModel
        self.coinPriceView = coinPriceView
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = coinPriceView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSwipeGestures()
        setupBinding()
        setupSearchButton()
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
        let currentExchange = viewModel.outputs.currentExchangeValue
        let currentIndex = exchanges.firstIndex(of: currentExchange) ?? 0
        
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
        viewModel.inputs.selectExchange(exchanges[nextIndex])
        
        // 해당하는 마켓뷰 강조 표시
        let marketViews = coinPriceView.getMarketViews()
        if nextIndex < marketViews.count {
            marketViews[nextIndex].handleTap()
        }
    }
    
    // 검색 버튼 설정
    private func setupSearchButton() {
        coinPriceView.searchButton.rx.tap
            .bind(onNext: navigateToSearchViewController)
            .disposed(by: disposeBag)
    }
    
    private func navigateToSearchViewController() {
        let searchVC = SearchViewController(viewModel: SearchViewModel(
            getMarketPricesUseCase: GetMarketPricesUseCase(
                services: [BithumbService(), CoinOneService(), KorbitService(), UpbitService()],
                symbolService: SymbolService()
            ),
            manageFavoritesUseCase: ManageFavoritesUseCase()
        ))
        navigationController?.pushViewController(searchVC, animated: true)
    }
    
    private func setupBinding() {
        // 테이블뷰 데이터 바인딩과 candles 데이터를 결합
        Observable
            .combineLatest(
                viewModel.outputs.coinPrices,
                viewModel.outputs.candlesDict
            )
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
        
        // 셀 선택 처리
        coinPriceView.coinPriceTableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.viewModel.inputs.selectCoinPrice(at: indexPath.row)
                self?.coinPriceView.coinPriceTableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
        
        // 선택된 코인의 차트 화면으로 네비게이션
        //        Observable.combineLatest(
        //            viewModel.outputs.selectedCoinPrice,
        //            viewModel.outputs.currentExchange
        //        )
        //        .compactMap { coinPrice, exchange in
        //            guard let coinPrice = coinPrice else { return nil }
        //            return (coinPrice, exchange)
        //        }
        //        .subscribe(onNext: { [weak self] (coinPrice: MarketPrice, exchange: Exchange) in
        //            guard let self = self else { return }
        //            let chartViewModel = ChartViewModel(exchange: exchange, selectedCoins: [coinPrice])
        //            let chartVC = ChartViewController(viewModel: chartViewModel, coinPriceViewModel: self.viewModel)
        //            self.navigationController?.pushViewController(chartVC, animated: true)
        //        })
        //        .disposed(by: disposeBag)
        
        // 거래소 선택 이벤트 처리
        for subview in coinPriceView.getMarketViews() {
            subview.selectedExchange
                .subscribe(onNext: { [weak self] exchange in
                    self?.coinPriceView.resetMarketViews()
                    self?.coinPriceView.scrollToTop()
                    self?.viewModel.inputs.selectExchange(exchange)
                })
                .disposed(by: disposeBag)
        }
        
        // 에러 처리
        viewModel.outputs.error
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { error in })
            .disposed(by: disposeBag)
    }
}

extension CoinPriceViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}



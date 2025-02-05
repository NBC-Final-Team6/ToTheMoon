//
//  PopularCurrencyViewController.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/28/25.
//

import UIKit
import RxSwift
import RxCocoa

final class PopularCurrencyViewController: UIViewController {
    private let contentView = PopularCurrencyTableView()
    private let viewModel = PopularCurrencyViewModel()
    private let disposeBag = DisposeBag()
    
    override func loadView() {
        view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        viewModel.fetchPopularCoins()
        contentView.tableView.delegate = self
        contentView.tableView.dataSource = self
    }
    
    private func bindViewModel() {
        viewModel.popularCoins
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] a in
                print(a)
                self?.contentView.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        contentView.tableView.rx.modelSelected(MarketPrice.self)
            .subscribe(onNext: { [weak self] coin in
                self?.viewModel.toggleSelection(for: coin)
                self?.contentView.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        viewModel.isFavoriteButtonVisible
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isVisible in
                DispatchQueue.main.async {
                    self?.contentView.favoriteButton.isHidden = !isVisible
                    self?.contentView.favoriteButton.alpha = isVisible ? 1 : 0
                }
            })
            .disposed(by: disposeBag)
        
        contentView.favoriteButton.rx.tap
            .bind { [weak self] in
                guard let self = self, let containerVC = self.parent as? FavoritesContainerViewController else { return }
                self.viewModel.addSelectedToFavorites()
                self.contentView.tableView.reloadData()
                containerVC.selectedSegment.accept(.favoriteList)
            }
            .disposed(by: disposeBag)
    }
}

extension PopularCurrencyViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.popularCoins.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CoinPriceTableViewCell.identifier, for: indexPath) as? CoinPriceTableViewCell else {
            return UITableViewCell()
        }
        
        let (coin, candles) = viewModel.popularCoins.value[indexPath.row] // ✅ 차트 데이터 포함
        cell.configure(with: coin, candles: candles)
        
        let isSelected = viewModel.selectedCoins.value.contains(coin)
        cell.backgroundColor = isSelected ? .selected : .container
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let (coin, _) = viewModel.popularCoins.value[indexPath.row]
        viewModel.toggleSelection(for: coin)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}



//
//  FavoritesViewController.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import RxSwift
import RxCocoa

final class FavoritesViewController: UIViewController {
    private let favoritesView = FavoritesView()
    private let disposeBag = DisposeBag()
    private let viewModel = FavoritesViewModel()
    
    override func loadView() {
        self.view = favoritesView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = true
    }
    
    private func bindViewModel() {
        // 세그먼트 선택 상태와 UI 업데이트 바인딩
        favoritesView.segmentedControl.rx.selectedSegmentIndex
            .compactMap { FavoritesViewModel.SegmentType(rawValue: $0) }
            .bind(to: viewModel.selectedSegment)
            .disposed(by: disposeBag)
        
        // 뷰 상태 업데이트
        viewModel.selectedSegment
            .flatMapLatest { [unowned self] segment in
                self.viewModel.viewState(for: segment)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] viewState in
                self?.favoritesView.updateViewStates(
                    isSearchButtonHidden: viewState.isSearchButtonHidden,
                    isTableViewHidden: viewState.isTableViewHidden,
                    isVerticalStackHidden: viewState.isVerticalStackHidden,
                    isButtonStackHidden: viewState.isButtonStackHidden
                )
            })
            .disposed(by: disposeBag)
        
        // 테이블뷰 데이터 바인딩
        viewModel.favoriteCoins
            .bind(to: favoritesView.tableView.rx.items(cellIdentifier: "FavoriteCell")) { _, coin, cell in
                cell.textLabel?.text = coin
            }
            .disposed(by: disposeBag)
        
        // 관심 목록 개수 업데이트
        viewModel.favoriteCoins
            .map { $0.count }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] count in
                self?.favoritesView.updateSortLabel(with: count)
            })
            .disposed(by: disposeBag)
    }
    
    private func setupTableView() {
        favoritesView.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FavoriteCell")
    }
}

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
        setupTabCollectionViewLayout()
        bindTabCollectionView()
        bindViewModel()
        setupTableView()
    }
    
    private func setupTabCollectionViewLayout() {
        guard let layout = favoritesView.tabCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        layout.itemSize = CGSize(
            width: UIScreen.main.bounds.width / CGFloat(viewModel.tabs.value.count), // 탭 개수에 따라 셀 크기 조정
            height: 40 // 고정된 높이
        )
    }

    // UICollectionView Rx 바인딩 설정
    private func bindTabCollectionView() {
            // Rx 데이터 바인딩
            viewModel.tabs
                .bind(to: favoritesView.tabCollectionView.rx.items(cellIdentifier: "TabCell", cellType: TabCell.self)) { index, title, cell in
                    let isSelected = index == self.viewModel.selectedSegment.value.rawValue
                    cell.configure(with: title, isSelected: isSelected)
                }
                .disposed(by: disposeBag)

            // 탭 선택 이벤트 바인딩
            favoritesView.tabCollectionView.rx.itemSelected
                .subscribe(onNext: { [weak self] indexPath in
                    guard let self = self else { return }
                    self.animateUnderline(to: indexPath)
                    self.viewModel.selectedSegment.accept(FavoritesViewModel.SegmentType(rawValue: indexPath.item) ?? .favoriteList)
                })
                .disposed(by: disposeBag)

            // 탭 상태 업데이트
            viewModel.selectedSegment
                .subscribe(onNext: { [weak self] _ in
                    self?.favoritesView.tabCollectionView.reloadData()
                })
                .disposed(by: disposeBag)
        }

        private func animateUnderline(to indexPath: IndexPath) {
            guard let cell = favoritesView.tabCollectionView.cellForItem(at: indexPath) else { return }
            UIView.animate(withDuration: 0.3) {
                self.favoritesView.underlineView.snp.remakeConstraints { make in
                    make.bottom.equalTo(self.favoritesView.tabCollectionView)
                    make.height.equalTo(2)
                    make.leading.equalTo(cell.frame.origin.x)
                    make.width.equalTo(cell.frame.width)
                }
                self.favoritesView.layoutIfNeeded()
            }
        }

    private func bindViewModel() {
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
    }

    // 테이블 뷰 등록
    private func setupTableView() {
        favoritesView.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FavoriteCell")
    }
}

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
        bindTabCollectionView()
        bindViewModel()
        setupTableView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupTabCollectionViewLayout()
        setupInitialUnderlinePosition()
        favoritesView.tabCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func setupTabCollectionViewLayout() {
        guard let layout = favoritesView.tabCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        let tabCount = CGFloat(viewModel.tabs.value.count)
        let collectionViewWidth = favoritesView.tabCollectionView.bounds.width
        let tabWidth = collectionViewWidth / tabCount
        
        layout.itemSize = CGSize(
            width: tabWidth, // 각 탭의 너비를 정확히 계산
            height: 40 // 고정된 높이
        )
    }
    
    private func setupInitialUnderlinePosition() {
        // tabCollectionView의 inset 반영
        let collectionViewInsets: CGFloat = 16
        let tabWidth = (UIScreen.main.bounds.width - (collectionViewInsets * 2)) / CGFloat(viewModel.tabs.value.count)
        let selectedIndex = viewModel.selectedSegment.value.rawValue
        
        UIView.animate(withDuration: 0.0) { [weak self] in
            guard let self = self else { return }
            self.favoritesView.underlineView.snp.remakeConstraints { make in
                make.bottom.equalTo(self.favoritesView.tabCollectionView)
                make.height.equalTo(2)
                make.leading.equalTo(self.favoritesView.tabCollectionView.snp.leading).offset(tabWidth * CGFloat(selectedIndex)) // 수정된 위치
                make.width.equalTo(tabWidth) // 수정된 너비
            }
            self.favoritesView.layoutIfNeeded()
        }
    }

    // UICollectionView Rx 바인딩 설정
    private func bindTabCollectionView() {
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
                // 상태 먼저 업데이트
                self.viewModel.selectedSegment.accept(FavoritesViewModel.SegmentType(rawValue: indexPath.item) ?? .favoriteList)
                // 언더라인 애니메이션
                self.animateUnderline(to: indexPath)
                // 탭 컬렉션 뷰 리로드
                self.favoritesView.tabCollectionView.reloadData()
            })
            .disposed(by: disposeBag)
    }

    private func animateUnderline(to indexPath: IndexPath) {
        guard let cell = favoritesView.tabCollectionView.cellForItem(at: indexPath) else { return }
        // 레이아웃 강제 동기화
        favoritesView.tabCollectionView.layoutIfNeeded()
        UIView.animate(withDuration: 0.3) {
            self.favoritesView.underlineView.snp.remakeConstraints { make in
                make.bottom.equalTo(self.favoritesView.tabCollectionView)
                make.height.equalTo(2)
                // contentOffset을 고려한 leading 위치 계산
                let adjustedLeading = cell.frame.origin.x - self.favoritesView.tabCollectionView.contentOffset.x
                make.leading.equalTo(adjustedLeading)
                // 셀 너비로 언더라인 너비 설정
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

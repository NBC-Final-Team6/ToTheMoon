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

    private let tabs = ["인기 화폐", "관심 목록"]
    private let selectedSegment = BehaviorRelay<SegmentType>(value: .favoriteList)

    enum SegmentType: Int {
        case popularCurrency = 0
        case favoriteList
    }

    override func loadView() {
        self.view = favoritesView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        bindTabCollectionView()
        setupTableView()
        bindViewModel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupTabCollectionViewLayout()
        setupInitialUnderlinePosition()
        favoritesView.tabCollectionView.collectionViewLayout.invalidateLayout()
    }

    private func setupTabCollectionViewLayout() {
        guard let layout = favoritesView.tabCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        let tabCount = CGFloat(tabs.count)
        let collectionViewWidth = favoritesView.tabCollectionView.bounds.width
        let tabWidth = collectionViewWidth / tabCount
        
        layout.itemSize = CGSize(width: tabWidth, height: 40)
    }
    
    private func updateUnderlinePosition(index: Int, animated: Bool) {
        let tabWidth = favoritesView.tabCollectionView.bounds.width / CGFloat(tabs.count)
        let leadingOffset = 16 + tabWidth * CGFloat(index)
        UIView.animate(withDuration: animated ? 0.3 : 0.0) {
            self.favoritesView.underlineView.snp.remakeConstraints { make in
                make.bottom.equalTo(self.favoritesView.tabCollectionView)
                make.height.equalTo(2)
                make.leading.equalTo(leadingOffset)
                make.width.equalTo(tabWidth)
            }
            self.favoritesView.layoutIfNeeded()
        }
    }

    private func setupInitialUnderlinePosition() {
        let selectedIndex = selectedSegment.value.rawValue
        updateUnderlinePosition(index: selectedIndex, animated: false)
    }

    private func animateUnderline(to indexPath: IndexPath) {
        let selectedIndex = indexPath.item
        updateUnderlinePosition(index: selectedIndex, animated: true)
    }

    private func bindTabCollectionView() {
        // 탭 데이터 바인딩
        Observable.just(tabs)
            .bind(to: favoritesView.tabCollectionView.rx.items(cellIdentifier: "TabCell", cellType: TabCell.self)) { index, title, cell in
                let isSelected = index == self.selectedSegment.value.rawValue
                cell.configure(with: title, isSelected: isSelected)
            }
            .disposed(by: disposeBag)

        // 탭 선택 이벤트
        favoritesView.tabCollectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                self.selectedSegment.accept(SegmentType(rawValue: indexPath.item) ?? .favoriteList)
                self.animateUnderline(to: indexPath)
                self.favoritesView.tabCollectionView.reloadData()
            })
            .disposed(by: disposeBag)
    }

    private func bindViewModel() {
        // 세그먼트 상태에 따른 UI 업데이트
        selectedSegment
            .subscribe(onNext: { [weak self] segment in
                guard let self = self else { return }
                self.updateViewState(for: segment)
            })
            .disposed(by: disposeBag)
        
        // 관심 목록 데이터 변경 시 UI 업데이트
        viewModel.favoriteCoins
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.updateViewState(for: self.selectedSegment.value)
            })
            .disposed(by: disposeBag)
    }

    private func updateViewState(for segment: SegmentType) {
        switch segment {
        case .popularCurrency:
            // 인기 화폐 상태
            favoritesView.searchButton.isHidden = false
            favoritesView.tableView.isHidden = false
            favoritesView.verticalStackView.isHidden = true
            favoritesView.buttonStackView.isHidden = true

        case .favoriteList:
            // 관심 목록 상태
            let isEmpty = viewModel.favoriteCoins.value.isEmpty
            favoritesView.searchButton.isHidden = true
            favoritesView.tableView.isHidden = isEmpty
            favoritesView.verticalStackView.isHidden = !isEmpty
            favoritesView.buttonStackView.isHidden = false
        }
    }

    private func setupTableView() {
        favoritesView.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FavoriteCell")
    }
}

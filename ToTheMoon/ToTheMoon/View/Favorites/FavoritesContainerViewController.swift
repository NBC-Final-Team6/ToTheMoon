//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/27/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class FavoritesContainerViewController: UIViewController {
    private let topFavoritesView = TopFavoritesView() // 상단 UI 포함 공통 뷰
    private let tabs = ["인기 화폐", "관심 목록"]
    private let selectedSegment = BehaviorRelay<SegmentType>(value: .favoriteList)
    private let disposeBag = DisposeBag()

    private lazy var popularCurrencyVC = PopularCurrencyViewController()
    private lazy var favoriteListVC = FavoriteListViewController()

    override func loadView() {
        self.view = topFavoritesView
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        setupTabCollectionView()
        setupInitialView()
        bindSegmentSelection()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupTabCollectionViewLayout()
        setupInitialUnderlinePosition()
        topFavoritesView.tabCollectionView.collectionViewLayout.invalidateLayout()
    }

    private func setupTabCollectionView() {
        // 탭 데이터 바인딩
        Observable.just(tabs)
            .bind(to: topFavoritesView.tabCollectionView.rx.items(cellIdentifier: "TabCell", cellType: TabCell.self)) { index, title, cell in
                let isSelected = index == self.selectedSegment.value.rawValue
                cell.configure(with: title, isSelected: isSelected)
            }
            .disposed(by: disposeBag)

        // 탭 선택 이벤트
        topFavoritesView.tabCollectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                let selectedSegment = SegmentType(rawValue: indexPath.item) ?? .favoriteList
                self.selectedSegment.accept(selectedSegment)
                self.animateUnderline(to: indexPath.item)
                self.topFavoritesView.tabCollectionView.reloadData()
            })
            .disposed(by: disposeBag)
    }

    private func setupInitialView() {
        switchToViewController(for: .favoriteList)
    }

    private func bindSegmentSelection() {
        // 탭 전환에 따른 뷰 컨트롤러 변경 및 UI 업데이트
        selectedSegment
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] segment in
                guard let self = self else { return }
                self.switchToViewController(for: segment)
                self.updateTabUI(for: segment)
            })
            .disposed(by: disposeBag)
    }

    private func setupTabCollectionViewLayout() {
        guard let layout = topFavoritesView.tabCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        let tabCount = CGFloat(tabs.count)
        let collectionViewWidth = topFavoritesView.tabCollectionView.bounds.width
        let tabWidth = collectionViewWidth / tabCount
        
        layout.itemSize = CGSize(width: tabWidth, height: 40)
    }

    private func setupInitialUnderlinePosition() {
        let selectedIndex = selectedSegment.value.rawValue
        animateUnderline(to: selectedIndex)
    }

    private func switchToViewController(for segment: SegmentType) {
        // 기존 ViewController 제거 및 새 ViewController 추가
        if segment == .popularCurrency {
            remove(child: favoriteListVC)
            add(child: popularCurrencyVC)
        } else {
            remove(child: popularCurrencyVC)
            add(child: favoriteListVC)
        }
    }

    private func updateTabUI(for segment: SegmentType) {
        // 상단 탭 언더라인 위치 및 선택 상태 업데이트
        let index = segment.rawValue
        animateUnderline(to: index)
        topFavoritesView.tabCollectionView.reloadData()
    }

    private func animateUnderline(to index: Int) {
        let tabWidth = topFavoritesView.tabCollectionView.bounds.width / CGFloat(tabs.count)
        let leadingOffset = 16 + tabWidth * CGFloat(index)

        UIView.animate(withDuration: 0.3) {
            self.topFavoritesView.underlineView.snp.remakeConstraints { make in
                make.bottom.equalTo(self.topFavoritesView.tabCollectionView)
                make.height.equalTo(2)
                make.leading.equalTo(leadingOffset)
                make.width.equalTo(tabWidth)
            }
            self.topFavoritesView.layoutIfNeeded()
        }
    }

    private func add(child viewController: UIViewController) {
        addChild(viewController)
        topFavoritesView.contentView.addSubview(viewController.view)
        
        viewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        viewController.didMove(toParent: self)
    }

    private func remove(child viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
}

enum SegmentType: Int {
    case popularCurrency = 0
    case favoriteList
}

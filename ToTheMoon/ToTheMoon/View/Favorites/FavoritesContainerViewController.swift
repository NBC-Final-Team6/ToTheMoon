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
    private let topFavoritesView = TopFavoritesView()
    private let viewModel = FavoritesContainerViewModel()
    private let tabs = ["인기 화폐", "관심 목록"]
    let selectedSegment = BehaviorRelay<SegmentType>(value: .favoriteList)
    private let disposeBag = DisposeBag()
    
    private lazy var popularCurrencyVC = PopularCurrencyViewController()
    private lazy var getMarketPricesUseCase = GetMarketPricesUseCase()
    private lazy var favoriteListVC = FavoriteListViewController(
        viewModel: FavoritesListViewModel(
            manageFavoritesUseCase: ManageFavoritesUseCase(),
            getMarketPricesUseCase: getMarketPricesUseCase
        )
    )
    
    override func loadView() {
        self.view = topFavoritesView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionViewLayout()
        setupTabCollectionView()
        setupInitialView()
        bindSegmentSelection()
        bindSearchButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    private func setupCollectionViewLayout() {
        guard let layout = topFavoritesView.tabCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        let tabCount = CGFloat(tabs.count)
        let collectionViewWidth = UIScreen.main.bounds.width
        let tabWidth = (collectionViewWidth / tabCount) - 16
        
        layout.itemSize = CGSize(width: tabWidth, height: 40)
        layout.sectionInset = .zero
        
        DispatchQueue.main.async {
            let selectedIndex = self.selectedSegment.value.rawValue
            let leadingOffset = tabWidth * CGFloat(selectedIndex)
            self.topFavoritesView.underlineView.snp.remakeConstraints { make in
                make.bottom.equalTo(self.topFavoritesView.tabCollectionView)
                make.height.equalTo(2)
                make.trailing.equalToSuperview().offset(-16)
                make.width.equalTo(leadingOffset)
            }
            self.topFavoritesView.layoutIfNeeded()
        }
    }
    
    private func setupTabCollectionView() {
        topFavoritesView.tabCollectionView.delegate = self  // delegate 설정 추가
        
        Observable.just(tabs)
            .bind(to: topFavoritesView.tabCollectionView.rx.items(cellIdentifier: "TabCell", cellType: TabCell.self)) { [weak self] index, title, cell in
                guard let self = self else { return }
                let isSelected = index == self.selectedSegment.value.rawValue
                cell.configure(with: title, isSelected: isSelected)
            }
            .disposed(by: disposeBag)
        
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
        selectedSegment
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] segment in
                guard let self = self else { return }
                self.switchToViewController(for: segment)
                self.updateTabUI(for: segment)
                self.topFavoritesView.searchButton.isHidden = (segment == .popularCurrency)
            })
            .disposed(by: disposeBag)
    }
    
    private func updateTabUI(for segment: SegmentType) {
        let index = segment.rawValue
        animateUnderline(to: index)
        topFavoritesView.tabCollectionView.reloadData()
    }
    
    private func animateUnderline(to index: Int) {
        let tabWidth = topFavoritesView.tabCollectionView.frame.width / CGFloat(tabs.count)
        let leadingOffset = tabWidth * CGFloat(index)
        
        UIView.animate(withDuration: 0.3) {
            self.topFavoritesView.underlineView.snp.remakeConstraints { make in
                make.bottom.equalTo(self.topFavoritesView.tabCollectionView)
                make.height.equalTo(2)
                make.leading.equalTo(self.topFavoritesView.tabCollectionView).offset(leadingOffset)
                make.width.equalTo(tabWidth)
            }
            self.topFavoritesView.layoutIfNeeded()
        }
    }
    
    private func bindSearchButton() {
        
        topFavoritesView.searchButton.rx.tap
            .bind(to: viewModel.showSearchViewController)
            .disposed(by: disposeBag)
        
        viewModel.showSearchViewController
            .subscribe(onNext: { [weak self] in
                self?.navigateToSearchViewController()
            })
            .disposed(by: disposeBag)
    }
    
    private func navigateToSearchViewController() {
        let getMarketPricesUseCase = GetMarketPricesUseCase()
        let manageFavoritesUseCase = ManageFavoritesUseCase()
        let searchViewModel = SearchViewModel(
            getMarketPricesUseCase: getMarketPricesUseCase,
            manageFavoritesUseCase: manageFavoritesUseCase
        )
        let searchVC = SearchViewController(viewModel: searchViewModel)
        navigationController?.pushViewController(searchVC, animated: true)
    }
    
    
    private func switchToViewController(for segment: SegmentType) {
        if segment == .popularCurrency {
            remove(child: favoriteListVC)
            add(child: popularCurrencyVC)
        } else {
            remove(child: popularCurrencyVC)
            add(child: favoriteListVC)
        }
    }
    
    private func add(child viewController: UIViewController) {
        topFavoritesView.contentView.addSubview(viewController.view)
        viewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        topFavoritesView.contentView.layoutIfNeeded()
        addChild(viewController)
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

extension FavoritesContainerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width) / CGFloat(tabs.count)
        return CGSize(width: width, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
}

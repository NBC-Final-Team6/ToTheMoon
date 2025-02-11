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
    
    private lazy var getMarketPricesUseCase = GetMarketPricesUseCase()
    
    private var childControllers: [SegmentType: UIViewController] = [:]
    
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
     }
    
    private func setupTabCollectionView() {
        topFavoritesView.tabCollectionView.delegate = self
        
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
        
        let initialIndex = selectedSegment.value.rawValue
        DispatchQueue.main.async {
            self.setUnderlinePosition(to: initialIndex)
        }
    }
    
    private func setUnderlinePosition(to index: Int) {
        let tabWidth = topFavoritesView.tabCollectionView.frame.width / CGFloat(tabs.count)
        let leadingOffset = tabWidth * CGFloat(index)

        topFavoritesView.underlineView.snp.remakeConstraints { make in
            make.bottom.equalTo(topFavoritesView.tabCollectionView)
            make.height.equalTo(2)
            make.leading.equalTo(topFavoritesView.tabCollectionView).offset(leadingOffset)
            make.width.equalTo(tabWidth)
        }
        self.topFavoritesView.layoutIfNeeded()
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
        animateUnderline(to: segment.rawValue)
        topFavoritesView.tabCollectionView.reloadData()
        topFavoritesView.searchButton.isHidden = (segment == .popularCurrency)
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
    
    
    // MARK: - 뷰 컨트롤러 전환
    private func switchToViewController(for segment: SegmentType) {
        // 기존 화면 제거
        childControllers.values.forEach { removeChildVC($0) }
        // 새로운 화면 추가
        let newViewController = childControllers[segment] ?? createViewController(for: segment)
        addChildVC(newViewController)
        // 생성된 뷰 컨트롤러를 저장
        childControllers[segment] = newViewController
    }
    
    private func createViewController(for segment: SegmentType) -> UIViewController {
        switch segment {
        case .popularCurrency:
            return PopularCurrencyViewController()
        case .favoriteList:
            return FavoriteListViewController(
                viewModel: FavoritesListViewModel(
                    manageFavoritesUseCase: ManageFavoritesUseCase(),
                    getMarketPricesUseCase: getMarketPricesUseCase
                )
            )
        }
    }
    
    private func addChildVC(_ viewController: UIViewController) {
        topFavoritesView.contentView.addSubview(viewController.view)
        viewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.view.layoutIfNeeded()
        addChild(viewController)
        viewController.didMove(toParent: self)
    }
    
    private func removeChildVC(_ viewController: UIViewController) {
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

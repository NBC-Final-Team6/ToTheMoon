//
//  FavoritesViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import RxSwift
import RxCocoa

final class FavoritesListViewModel {
    
    // MARK: - Dependencies
    private let manageFavoritesUseCase: ManageFavoritesUseCaseProtocol
    let fetchFavoriteCoinsUseCase: FetchFavoriteCoinsUseCase
    private let disposeBag = DisposeBag()
    
    // MARK: - Input
    struct Input {
        let removeFavorite = PublishRelay<MarketPrice>()
        let searchTrigger = PublishRelay<Void>()
    }
    
    // MARK: - Output
    struct Output {
        let favoriteCoins: Driver<[MarketPrice]>
        let isLoading: Driver<Bool>
        let navigateToSearch: Signal<Void>
    }
    
    // MARK: - Properties
    let input = Input()
    let output: Output
    
    private let favoriteCoinsRelay = BehaviorRelay<[MarketPrice]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Init
    init(manageFavoritesUseCase: ManageFavoritesUseCaseProtocol, fetchFavoriteCoinsUseCase: FetchFavoriteCoinsUseCase) {
        self.manageFavoritesUseCase = manageFavoritesUseCase
        self.fetchFavoriteCoinsUseCase = fetchFavoriteCoinsUseCase
        
        self.output = Output(
            favoriteCoins: favoriteCoinsRelay.asDriver(onErrorJustReturn: []),
            isLoading: isLoadingRelay.asDriver(onErrorJustReturn: false),
            navigateToSearch: input.searchTrigger.asSignal()
        )
        
        bindInputs()
        observeFavoriteCoins()
    }
    
    // MARK: - Bind Input to Output
    private func bindInputs() {
        input.removeFavorite
            .flatMapLatest { [weak self] coin -> Observable<Void> in
                guard let self = self else { return .empty() }
                return self.manageFavoritesUseCase.removeCoin(coin)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.fetchFavoriteCoins()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - CoreData 변경 감지 후 웹소켓 업데이트
    private func observeFavoriteCoins() {
        manageFavoritesUseCase.fetchFavoriteCoins()
            .distinctUntilChanged { $0 == $1 } // ✅ 중복 데이터 방지
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance) // ✅ 변경 감지 후 300ms 대기
            .subscribe(onNext: { [weak self] _ in
                print("🔄 관심 코인 목록 변경 감지됨 → 웹소켓 재구독 실행")
                self?.fetchFavoriteCoins()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Fetch Favorite Coins (웹소켓 사용)
    func fetchFavoriteCoins() {
        isLoadingRelay.accept(true)
        
        fetchFavoriteCoinsUseCase.fetchFavoriteCoinsRealtimeData()
            .observe(on: MainScheduler.instance)
            .scan(favoriteCoinsRelay.value) { existingData, newMarketPrices in
                var updatedData = existingData
                
                // ✅ 기존 데이터와 새로운 데이터를 병합하면서 업데이트
                for marketPrice in newMarketPrices {
                    if let index = updatedData.firstIndex(where: { $0.exchange == marketPrice.exchange && $0.symbol == marketPrice.symbol }) {
                        updatedData[index] = marketPrice // 기존 데이터 업데이트
                    } else {
                        updatedData.append(marketPrice) // 새로운 데이터 추가
                    }
                }
    
                print("✅ [DEBUG] UI 업데이트 전 최종 데이터:")
                updatedData.forEach { print("   💰 \($0.exchange) - \($0.symbol): \($0.price) KRW") }
                
                return updatedData
            }
            .subscribe(onNext: { [weak self] updatedPrices in
                guard let self = self else { return }
                self.isLoadingRelay.accept(false)
                self.favoriteCoinsRelay.accept(updatedPrices) // 기존 데이터 유지하면서 업데이트
            })
            .disposed(by: disposeBag)
    }
    
    deinit {
        print("🔴 FavoritesListViewModel deinit - 웹소켓 연결 해제")
        fetchFavoriteCoinsUseCase.cancelSubscriptions() // 뷰모델이 해제될 때 웹소켓 해제
    }
}

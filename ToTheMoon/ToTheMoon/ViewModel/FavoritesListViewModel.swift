import RxSwift
import RxCocoa

final class FavoritesListViewModel {
    
    // MARK: - Dependencies
    private let manageFavoritesUseCase: ManageFavoritesUseCaseProtocol
    private let getMarketPricesUseCase: GetMarketPricesUseCase
    private let disposeBag = DisposeBag()
    
    // MARK: - Input
    struct Input {
        let fetchTrigger: PublishRelay<Void>
        let removeFavorite: PublishRelay<MarketPrice>
    }
    
    // MARK: - Output
    struct Output {
        let favoriteCoins: Driver<[MarketPrice]>
        let isLoading: Driver<Bool>
    }
    
    // MARK: - Properties
    let input: Input
    let output: Output
    
    private let favoriteCoinsRelay = BehaviorRelay<[MarketPrice]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Init
    init(manageFavoritesUseCase: ManageFavoritesUseCaseProtocol, getMarketPricesUseCase: GetMarketPricesUseCase) {
        self.manageFavoritesUseCase = manageFavoritesUseCase
        self.getMarketPricesUseCase = getMarketPricesUseCase
        
        let fetchTrigger = PublishRelay<Void>()
        let removeFavorite = PublishRelay<MarketPrice>()
        
        self.input = Input(fetchTrigger: fetchTrigger, removeFavorite: removeFavorite)
        self.output = Output(
            favoriteCoins: favoriteCoinsRelay.asDriver(onErrorJustReturn: []),
            isLoading: isLoadingRelay.asDriver(onErrorJustReturn: false)
        )
        
        bind()
    }
    
    // MARK: - Bind Input to Output
    private func bind() {
        // ⭐ 즐겨찾기 데이터 로딩
        input.fetchTrigger
            .subscribe(onNext: { [weak self] in
                self?.fetchFavoriteCoins()
            })
            .disposed(by: disposeBag)
        
        // ⭐ 즐겨찾기 코인 삭제 처리
        input.removeFavorite
            .flatMapLatest { [weak self] coin -> Observable<Void> in
                guard let self = self else { return .empty() }
                return self.manageFavoritesUseCase.removeCoin(coin)
            }
            .subscribe(onNext: { [weak self] in
                self?.fetchFavoriteCoins()
            }, onError: { error in
                print("❌ 즐겨찾기 삭제 실패: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Fetch Favorite Coins
    private func fetchFavoriteCoins() {
        isLoadingRelay.accept(true) // ✅ 데이터 로딩 시작
        
        let savedCoinsObservable = manageFavoritesUseCase.fetchFavoriteCoins()
            .do(onNext: { savedCoins in
                print("✅ fetchFavoriteCoins() 내부에서 저장된 코인 가져오기 성공: \(savedCoins)")
            }, onError: { error in
                print("❌ fetchFavoriteCoins() 내부 오류: \(error.localizedDescription)")
            })
            .asObservable()
        
        let allMarketPricesSingle = getMarketPricesUseCase.execute()
        
        Observable.combineLatest(savedCoinsObservable, allMarketPricesSingle.asObservable())
            .map { savedCoins, marketPrices in
                return marketPrices.filter { marketPrice in
                    savedCoins.contains { $0.symbol == marketPrice.symbol && $0.exchangename == marketPrice.exchange }
                }
            }
            .subscribe(onNext: { [weak self] filteredMarketPrices in
                self?.favoriteCoinsRelay.accept(filteredMarketPrices)
                self?.isLoadingRelay.accept(false) // ✅ 데이터 로딩 완료
            }, onError: { error in
                print("❌ 코인 가격 가져오기 실패: \(error.localizedDescription)")
                self.isLoadingRelay.accept(false) // ✅ 오류 발생 시 로딩 상태 해제
            })
            .disposed(by: disposeBag)
    }
}

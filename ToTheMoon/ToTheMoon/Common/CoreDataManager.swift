//
//  CoreDataManager.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import CoreData
import RxSwift

class CoreDataManager {
    
    static let shared = CoreDataManager()
    
    // 데이터 모델 이름을 지정
    private let modelName = "ToTheMoon"

    // Persistent Container 초기화
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()

    // 메인 컨텍스트 반환
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Create Coin (MarketPrice 저장)
    func createCoin(marketPrice: MarketPrice) -> Observable<Void> {
        return Observable.create { observer in
            let fetchRequest: NSFetchRequest<CoinEntities> = CoinEntities.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "symbol == %@ AND exchange == %@", marketPrice.symbol, marketPrice.exchange)

            do {
                let existingCoins = try self.context.fetch(fetchRequest)
                if !existingCoins.isEmpty {
                    observer.onError(NSError(domain: "CoreDataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "이미 존재하는 코인"]))
                    return Disposables.create()
                }

                let coin = CoinEntities(context: self.context)
                coin.symbol = marketPrice.symbol
                coin.exchange = marketPrice.exchange
                coin.price = marketPrice.price
                coin.change = marketPrice.change
                coin.changeRate = marketPrice.changeRate
                coin.quoteVolume = marketPrice.quoteVolume
                coin.highPrice = marketPrice.highPrice
                coin.lowPrice = marketPrice.lowPrice

                try self.context.save()
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    // MARK: - Fetch Coins (MarketPrice로 변환하여 반환)
    func fetchCoins() -> Observable<[MarketPrice]> {
        return Observable.create { observer in
            let fetchRequest: NSFetchRequest<CoinEntities> = CoinEntities.fetchRequest()

            do {
                let coins = try self.context.fetch(fetchRequest)
                let marketPrices = coins.map { coin in
                    MarketPrice(
                        symbol: coin.symbol ?? "",
                        price: coin.price,
                        exchange: coin.exchange ?? "",
                        change: coin.change ?? "",
                        changeRate: coin.changeRate,
                        quoteVolume: coin.quoteVolume,
                        highPrice: coin.highPrice,
                        lowPrice: coin.lowPrice,
                        image: nil // CoreData에는 이미지 저장 X, 외부에서 추가
                    )
                }
                observer.onNext(marketPrices)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    // MARK: - Update Coin (MarketPrice 기반 업데이트)
    func updateCoin(marketPrice: MarketPrice) -> Observable<Void> {
        return Observable.create { observer in
            let fetchRequest: NSFetchRequest<CoinEntities> = CoinEntities.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "symbol == %@ AND exchange == %@", marketPrice.symbol, marketPrice.exchange)

            do {
                let coins = try self.context.fetch(fetchRequest)
                if let coinToUpdate = coins.first {
                    coinToUpdate.price = marketPrice.price
                    coinToUpdate.change = marketPrice.change
                    coinToUpdate.changeRate = marketPrice.changeRate
                    coinToUpdate.quoteVolume = marketPrice.quoteVolume
                    coinToUpdate.highPrice = marketPrice.highPrice
                    coinToUpdate.lowPrice = marketPrice.lowPrice

                    try self.context.save()
                    observer.onNext(())
                    observer.onCompleted()
                } else {
                    observer.onError(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "업데이트할 코인을 찾을 수 없습니다."]))
                }
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    // MARK: - Delete Coin
    func deleteCoin(symbol: String, exchange: String) -> Observable<Void> {
        return Observable.create { observer in
            let fetchRequest: NSFetchRequest<CoinEntities> = CoinEntities.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "symbol == %@ AND exchangename == %@", symbol, exchange)

            do {
                let coins = try self.context.fetch(fetchRequest)
                if let coinToDelete = coins.first {
                    self.context.delete(coinToDelete)
                    try self.context.save()
                    observer.onNext(())
                    observer.onCompleted()
                } else {
                    observer.onError(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "삭제할 코인을 찾을 수 없습니다."]))
                }
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }
}


//
//  CoreDataManger.swift
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
        container.loadPersistentStores { description, error in
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

    // MARK: - Create Coin
    func createCoin(name: String, symbol: String, exchange: String) -> Observable<Void> {
        return Observable.create { observer in
            let coin = Coin(context: self.context)
            coin.id = UUID()
            coin.coinname = name
            coin.symbol = symbol
            coin.exchangename = exchange

            do {
                try self.context.save()
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    // MARK: - Fetch Coins
    func fetchCoins() -> Observable<[Coin]> {
        return Observable.create { observer in
            let fetchRequest: NSFetchRequest<Coin> = Coin.fetchRequest()

            do {
                let coins = try self.context.fetch(fetchRequest)
                observer.onNext(coins)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    // MARK: - Update Coin
    func updateCoin(coin: Coin, name: String? = nil, symbol: String? = nil, exchange: String? = nil) -> Observable<Void> {
        return Observable.create { observer in
            if let name = name { coin.coinname = name }
            if let symbol = symbol { coin.symbol = symbol }
            if let exchange = exchange { coin.exchangename = exchange }

            do {
                try self.context.save()
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    // MARK: - Delete Coin
    func deleteCoin(coin: Coin) -> Observable<Void> {
        return Observable.create { observer in
            self.context.delete(coin)

            do {
                try self.context.save()
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }
}
//테스트

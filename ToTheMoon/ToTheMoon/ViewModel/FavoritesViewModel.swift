//
//  FavoritesViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import RxSwift
import RxCocoa

final class FavoritesViewModel {
    
    let favoriteCoins = BehaviorRelay<[String]>(value: [])
}

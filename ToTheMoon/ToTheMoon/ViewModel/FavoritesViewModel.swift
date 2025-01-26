//
//  FavoritesViewModel.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import RxSwift
import RxCocoa

final class FavoritesViewModel {
    // 관심 목록 데이터
    let favoriteCoins = BehaviorRelay<[String]>(value: [])
    // 선택된 세그먼트
    let selectedSegment = BehaviorRelay<SegmentType>(value: .favoriteList)

    enum SegmentType: Int {
        case popularCurrency = 0
        case favoriteList
    }

    // 탭 데이터
    let tabs = BehaviorRelay<[String]>(value: ["인기 화폐", "관심 목록"])

    // 뷰 상태 생성
    func viewState(for segment: SegmentType) -> Observable<ViewState> {
        favoriteCoins.map { coins in
            switch segment {
            case .popularCurrency:
                return ViewState(
                    isSearchButtonHidden: false,
                    isTableViewHidden: false,
                    isVerticalStackHidden: true,
                    isButtonStackHidden: true
                )
            case .favoriteList:
                let isEmpty = coins.isEmpty
                return ViewState(
                    isSearchButtonHidden: true,
                    isTableViewHidden: isEmpty,
                    isVerticalStackHidden: !isEmpty,
                    isButtonStackHidden: false
                )
            }
        }
    }
}

struct ViewState {
    let isSearchButtonHidden: Bool
    let isTableViewHidden: Bool
    let isVerticalStackHidden: Bool
    let isButtonStackHidden: Bool
}

//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/27/25.
//

import UIKit
import SnapKit

final class FavoriteListViewController: UIViewController {
    private let noFavoritesView = NoFavoritesView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        // 배경색 설정
        view.backgroundColor = .background
        // NoFavoritesView 추가
        view.addSubview(noFavoritesView)

        // NoFavoritesView를 부모 뷰에 맞게 레이아웃 설정
        noFavoritesView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // NoFavoritesView 초기 상태 설정
        updateNoFavoritesView(isHidden: false)
    }

    // NoFavoritesView의 표시 상태를 업데이트하는 메서드
    func updateNoFavoritesView(isHidden: Bool) {
        noFavoritesView.isHidden = isHidden
    }
}

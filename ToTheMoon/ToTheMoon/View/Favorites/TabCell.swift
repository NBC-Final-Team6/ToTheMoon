//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/26/25.
//

import UIKit

class TabCell: UICollectionViewCell {
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        titleLabel.textAlignment = .center
        titleLabel.font = .medium.regular()
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with title: String, isSelected: Bool) {
        titleLabel.text = title
        // 선택 여부에 따라 글씨 색상 애니메이션 적용
        UIView.transition(with: titleLabel, duration: 0.3, options: .transitionCrossDissolve) {
            self.titleLabel.textColor = isSelected ? .text : .lightGray
            self.titleLabel.font = isSelected
            ? UIFont.medium.bold() : UIFont.medium.regular()
        }
    }
}


//
//  CustomSearchCell.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/28/25.
//

import UIKit
import SnapKit

final class CustomSearchCell: UITableViewCell {
    
    static let identifier = "CustomSearchCell"

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .medium.regular()
        label.textColor = .text
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .small.regular()
        label.textColor = .text
        label.textAlignment = .right
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        [iconImageView, titleLabel, dateLabel].forEach { contentView.addSubview($0) }

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        dateLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }

    func configure(with title: String, date: String, image: UIImage?) {
        titleLabel.text = title
        dateLabel.text = date
        iconImageView.image = image
    }
}

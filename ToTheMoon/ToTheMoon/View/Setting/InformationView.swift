//
//  InformationView.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import SnapKit

class InformationView: UIView {
    let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .white
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return button
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "앱 정보"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 30)
        label.textAlignment = .center
        return label
    }()

    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(named: "ContainerColor")
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        return view
    }()

    let currentVersionLabel: UILabel = {
        let label = UILabel()
        label.text = "현재 버전: 0.001"
        label.textColor = .white
        label.font = .systemFont(ofSize: 24, weight: .medium)
        return label
    }()

    let latestVersionLabel: UILabel = {
        let label = UILabel()
        label.text = "최신 버전: 0.001"
        label.textColor = .white
        label.font = .systemFont(ofSize: 24, weight: .medium)
        return label
    }()

    let separatorLine1: UIView = {
        let view = UIView()
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor(named: "BackgroundColor")
        separatorLine1.backgroundColor = UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1)


        addSubview(backButton)
        addSubview(titleLabel)
        addSubview(containerView)

        containerView.addSubview(currentVersionLabel)
        containerView.addSubview(separatorLine1)
        containerView.addSubview(latestVersionLabel)

        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.top.equalTo(safeAreaLayoutGuide).offset(10)
            make.width.height.equalTo(40)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
        }

        containerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(100)
        }

        currentVersionLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
        }

        separatorLine1.snp.makeConstraints { make in
            make.top.equalTo(currentVersionLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(1)
        }

        latestVersionLabel.snp.makeConstraints { make in
            make.top.equalTo(separatorLine1.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
        }
    }
}

//
//  CustomTabBarView.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import SnapKit

class CustomTabBarView: UIView {
    private var buttons: [UIButton] = []
    private let titles = ["관심 목록", "코인 시세", "앱 설정"]
    private let icons = ["cart.fill", "chart.bar.fill", "gearshape.fill"]

    var onTabSelected: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.backgroundColor = UIColor(red: 11/255, green: 11/255, blue: 40/255, alpha: 1)
        self.layer.masksToBounds = false
        self.clipsToBounds = true

        for (index, iconName) in icons.enumerated() {
            // 버튼 생성
            let button = UIButton(type: .system)
            
            // 스택뷰 (아이콘 + 텍스트)
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.alignment = .center
            stackView.spacing = 4

            // 아이콘
            let imageView = UIImageView(image: UIImage(systemName: iconName))
            imageView.tintColor = index == 0 ? UIColor(named: "PersonelColor") : UIColor(named: "TabBarTextColor")
            imageView.contentMode = .scaleAspectFit
            imageView.snp.makeConstraints { make in
                make.size.equalTo(24)
            }

            // 텍스트
            let label = UILabel()
            label.text = titles[index]
            label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
            label.textColor = index == 0 ? UIColor(named: "PersonelColor") : UIColor(named: "TabBarTextColor")

            // 스택뷰에 추가
            stackView.addArrangedSubview(imageView)
            stackView.addArrangedSubview(label)

            // 버튼에 스택뷰 추가
            button.addSubview(stackView)
            stackView.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }

            button.tag = index
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            buttons.append(button)
            self.addSubview(button)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let buttonWidth = self.bounds.width / CGFloat(buttons.count)
        let buttonHeight = self.bounds.height

        for (index, button) in buttons.enumerated() {
            button.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(CGFloat(index) * buttonWidth)
                make.top.bottom.equalToSuperview().inset(15)
                make.width.equalTo(buttonWidth)
            }
        }
    }

    @objc private func buttonTapped(_ sender: UIButton) {
        updateButtonSelection(selectedIndex: sender.tag)
        onTabSelected?(sender.tag)
    }

    private func updateButtonSelection(selectedIndex: Int) {
        for (index, button) in buttons.enumerated() {
            let stackView = button.subviews.first(where: { $0 is UIStackView }) as? UIStackView
            let imageView = stackView?.arrangedSubviews.first as? UIImageView
            let label = stackView?.arrangedSubviews.last as? UILabel

            imageView?.tintColor = index == selectedIndex ? UIColor(named: "PersonelColor") : UIColor(named: "TabBarTextColor")
            label?.textColor = index == selectedIndex ? UIColor(named: "PersonelColor") : UIColor(named: "TabBarTextColor")
        }
    }
}

// SwiftUI Preview
@available(iOS 17.0, *)
#Preview {
    CustomTabBarView()
}

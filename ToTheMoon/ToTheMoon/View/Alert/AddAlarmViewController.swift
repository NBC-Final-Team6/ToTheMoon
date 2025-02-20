//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/20/25.
//

import UIKit
import SnapKit

class AddAlarmViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    var onAlarmAdded: (() -> Void)?

    private let coinPicker = UIPickerView()
    private let priceTextField = UITextField()
    private let conditionSegment = UISegmentedControl(items: ["이상", "이하"])
    private let saveButton = UIButton()

    private let coins = ["BTC", "ETH", "XRP", "DOGE"]
    private var selectedCoin = "BTC"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "알람 추가"
        view.backgroundColor = .white

        coinPicker.delegate = self
        coinPicker.dataSource = self

        priceTextField.placeholder = "목표 가격 입력"
        priceTextField.borderStyle = .roundedRect
        priceTextField.keyboardType = .decimalPad

        conditionSegment.selectedSegmentIndex = 0

        saveButton.setTitle("저장", for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.layer.cornerRadius = 5
        saveButton.addTarget(self, action: #selector(saveAlarm), for: .touchUpInside)

        view.addSubview(coinPicker)
        view.addSubview(priceTextField)
        view.addSubview(conditionSegment)
        view.addSubview(saveButton)

        coinPicker.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalTo(150)
        }

        priceTextField.snp.makeConstraints { make in
            make.top.equalTo(coinPicker.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(40)
        }

        conditionSegment.snp.makeConstraints { make in
            make.top.equalTo(priceTextField.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(50)
        }

        saveButton.snp.makeConstraints { make in
            make.top.equalTo(conditionSegment.snp.bottom).offset(40)
            make.centerX.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(50)
        }
    }

    @objc private func saveAlarm() {
        guard let priceText = priceTextField.text, let price = Double(priceText) else {
            return
        }

        let isHigher = conditionSegment.selectedSegmentIndex == 0
        let newAlarm = CoinAlarm(coin: selectedCoin, targetPrice: price, isHigher: isHigher)

        var alarms = CoinAlarmManager.shared.loadAlarms()
        alarms.append(newAlarm)
        CoinAlarmManager.shared.saveAlarms(alarms)

        onAlarmAdded?()
        navigationController?.popViewController(animated: true)
    }

    // MARK: - UIPickerView Delegate & DataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return coins.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return coins[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedCoin = coins[row]
    }
}

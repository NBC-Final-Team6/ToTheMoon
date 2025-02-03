//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/2/25.
//

import UIKit
import SnapKit

final class LoadingView: UIView {
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.textColor = .text
        label.font = .medium.bold()
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .background
        
        [ activityIndicator, loadingLabel].forEach{ addSubview($0) }
        
        activityIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
        }
        
        loadingLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(activityIndicator.snp.bottom).offset(10)
        }
    }
    
    func startLoading() {
        isHidden = false
        activityIndicator.startAnimating()
    }
    
    func stopLoading() {
        isHidden = true
        activityIndicator.stopAnimating()
    }
}

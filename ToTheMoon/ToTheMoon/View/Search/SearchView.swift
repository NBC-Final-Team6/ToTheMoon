//
//  SearchView.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import SnapKit

final class SearchView: UIView {
    
    let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.backgroundImage = UIImage() // 배경 제거
        searchBar.searchTextField.backgroundColor = .background
        searchBar.searchTextField.textColor = .text
        searchBar.searchTextField.font = .systemFont(ofSize: 16)
        searchBar.searchTextField.layer.borderColor = UIColor.personel.cgColor
        searchBar.searchTextField.layer.borderWidth = 1.0
        searchBar.searchTextField.layer.cornerRadius = 8 // 원하는 모서리 곡률
        searchBar.searchTextField.clipsToBounds = true
        
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.personel, // 원하는 색상
            .font: UIFont.medium.regular()
        ]
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: "검색어를 입력해 주세요.", attributes: placeholderAttributes)
        
        if let glassIconView = searchBar.searchTextField.leftView as? UIImageView {
            glassIconView.tintColor = .personel // 원하는 색상
        }
        return searchBar
    }()
    
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SearchCell")
        tableView.separatorStyle = .singleLine
        tableView.layer.cornerRadius = 30
        tableView.backgroundColor = .clear
        return tableView
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

        [ searchBar, tableView ].forEach{ addSubview($0)  }
                   
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

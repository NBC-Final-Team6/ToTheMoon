//
//  SearchViewController.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit

final class SearchViewController: UIViewController {
    private let searchView = SearchView()
    
    private var recentSearches: [(String, String)] = [
        ("BTC Upbit", "2024.01.21"),
        ("ETH Upbit", "2024.01.20"),
        ("DOGE Upbit", "2024.01.19"),
        ("ADA Upbit", "2024.01.18")
    ]

    override func loadView() {
        view = searchView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        setupTableView()
    }

    private func setupBindings() {
        // Clear 버튼 동작 설정
        searchView.clearButton.addTarget(self, action: #selector(clearSearchHistory), for: .touchUpInside)
    }

    private func setupTableView() {
        searchView.tableView.delegate = self
        searchView.tableView.dataSource = self
        searchView.tableView.register(CustomSearchCell.self, forCellReuseIdentifier: CustomSearchCell.identifier)
    }

    @objc private func clearSearchHistory() {
        recentSearches.removeAll()
        searchView.tableView.reloadData()
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentSearches.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CustomSearchCell.identifier, for: indexPath) as? CustomSearchCell else {
            return UITableViewCell()
        }

        let search = recentSearches[indexPath.row]
        cell.configure(with: search.0, date: search.1)
        return cell
    }
}

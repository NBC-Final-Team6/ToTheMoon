//
//  FavoritesViewController.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import RxSwift
import RxCocoa

final class FavoritesViewController: UIViewController {
    private let favoritesView = FavoritesView()
    private let disposeBag = DisposeBag()

    private var favoriteCoins: [String] = [] { // 관심 목록 데이터
        didSet {
            updateUI()
        }
    }
    
    override func loadView() {
        self.view = favoritesView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSegmentedControlAction()
        setupTableView()
        //loadDummyData()
    }
    
    private func setupSegmentedControlAction() {
        favoritesView.segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)
    }
    
    private func setupTableView() {
        favoritesView.tableView.dataSource = self
        favoritesView.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FavoriteCell")
    }
    
    private func loadDummyData() {
           // 더미 데이터 추가
           favoriteCoins = [
               "Bitcoin",
               "Ethereum",
               "Ripple",
               "Cardano",
               "Solana"
           ]
       }
    
    @objc private func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 { // "인기 화폐" 선택 시
            favoritesView.verticalStackView.isHidden = true
            favoritesView.tableView.isHidden = false
        } else { // "관심 목록" 선택 시
            let isTableViewHidden = favoriteCoins.isEmpty
            favoritesView.tableView.isHidden = isTableViewHidden
            favoritesView.verticalStackView.isHidden = !isTableViewHidden
        }
    }
    
    private func updateUI() {
        favoritesView.tableView.reloadData()
        let isTableViewHidden = favoriteCoins.isEmpty
        favoritesView.tableView.isHidden = isTableViewHidden
        favoritesView.verticalStackView.isHidden = !isTableViewHidden
    }
}

// MARK: - UITableViewDataSource
extension FavoritesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoriteCoins.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell", for: indexPath)
        cell.textLabel?.text = favoriteCoins[indexPath.row]
        return cell
    }
}

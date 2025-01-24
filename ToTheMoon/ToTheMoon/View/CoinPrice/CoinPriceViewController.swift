//
//  CoinPriceViewController.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import RxSwift

class CoinPriceViewController: UIViewController {
    
    private let coinPriceView = CoinPriceView()
    
    private var coinPrices: [CoinPrice] = [CoinPrice(coinName: "비트코인", marketName: "업비트", price: 1600000000.0, priceChange: 1), CoinPrice(coinName: "비트코인", marketName: "업비트", price: 160.0, priceChange: -0.4)]
    
    override func loadView() {
        view = coinPriceView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        coinPriceView.coinPriceTableView.dataSource = self
        coinPriceView.coinPriceTableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
}

extension CoinPriceViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return coinPrices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CoinPriceTableViewCell.identifier, for: indexPath) as? CoinPriceTableViewCell else {
            return UITableViewCell()
        }
        
        let coinPrice = coinPrices[indexPath.row]
        cell.configure(with: coinPrice)
        return cell
    }
}

extension CoinPriceViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

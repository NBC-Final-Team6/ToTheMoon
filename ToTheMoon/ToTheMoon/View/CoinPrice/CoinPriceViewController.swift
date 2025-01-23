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
    
    override func loadView() {
        view = coinPriceView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        
    }
    
}

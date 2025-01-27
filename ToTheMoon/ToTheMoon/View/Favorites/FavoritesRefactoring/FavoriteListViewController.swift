//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/27/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class FavoriteListViewController: UIViewController {
    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.frame = view.bounds // AutoLayout으로 교체 가능
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FavoriteListCell")
    }
}

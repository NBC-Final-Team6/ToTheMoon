//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/13/25.
//

import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UIViewController {
    
    var loadView: Observable<Void> {
        return methodInvoked(#selector(UIViewController.loadView))
            .map { _ in }
    }
    
    var viewDidLoad: Observable<Void> {
        return methodInvoked(#selector(UIViewController.viewDidLoad))
            .map { _ in }
    }
    
    var viewWillAppear: Observable<Void> {
        return methodInvoked(#selector(UIViewController.viewWillAppear(_:)))
            .map { _ in }
    }
    
    var viewWillDisappear: Observable<Void> {
        return methodInvoked(#selector(UIViewController.viewWillAppear(_:)))
            .map { _ in }
    }
    
}


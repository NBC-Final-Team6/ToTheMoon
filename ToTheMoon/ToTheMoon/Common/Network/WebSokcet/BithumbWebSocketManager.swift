//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/11/25.
//

import Foundation
import Starscream
import RxSwift

final class BithumbWebSocketManager: BaseWebSocketManager {
    static let shared = BithumbWebSocketManager()
    private override init() {}
}

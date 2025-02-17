//
//  Untitled.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/14/25.
//

import Foundation
import RxSwift

protocol WebSocketServiceProtocol {
    var exchange: Exchange { get }
    func fetchAllKrwTickers() -> Observable<[MarketPrice]>
    func fetchKrwTicker(for symbols: [String]) -> Observable<[MarketPrice]>
    func disconnectWebSocket()
}

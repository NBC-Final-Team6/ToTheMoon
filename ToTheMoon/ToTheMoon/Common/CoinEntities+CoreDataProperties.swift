//
//  CoinEntities+CoreDataProperties.swift
//  ToTheMoon
//
//  Created by 황석범 on 2/17/25.
//
//

import Foundation
import CoreData


extension CoinEntities {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoinEntities> {
        return NSFetchRequest<CoinEntities>(entityName: "CoinEntities")
    }

    @NSManaged public var symbol: String?
    @NSManaged public var price: Double
    @NSManaged public var exchange: String?
    @NSManaged public var change: String?
    @NSManaged public var changeRate: Double
    @NSManaged public var quoteVolume: Double
    @NSManaged public var highPrice: Double
    @NSManaged public var lowPrice: Double

}

extension CoinEntities : Identifiable {

}

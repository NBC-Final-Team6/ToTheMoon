//
//  Coin+CoreDataProperties.swift
//  ToTheMoon
//
//  Created by 강민성 on 1/22/25.
//
//

import Foundation
import CoreData


extension Coin {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Coin> {
        return NSFetchRequest<Coin>(entityName: "Coin")
    }

    @NSManaged public var coinname: String?
    @NSManaged public var exchangename: String?
    @NSManaged public var id: UUID?
    @NSManaged public var symbol: String?

}

extension Coin : Identifiable {

}

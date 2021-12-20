//
//  Batch+CoreDataProperties.swift
//  CoreDataManager_Example
//
//  Created by Nguyen Truong Luu on 12/19/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//
//

import Foundation
import CoreData


extension Batch {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Batch> {
        return NSFetchRequest<Batch>(entityName: entityName)
    }

    @NSManaged public var id: NSNumber
    @NSManaged public var name: String?
    @NSManaged public var clicks: NSSet?

}

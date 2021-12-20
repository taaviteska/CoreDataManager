//
//  Click+CoreDataProperties.swift
//  CoreDataManager_Example
//
//  Created by Nguyen Truong Luu on 12/19/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//
//

import Foundation
import CoreData


extension Click {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Click> {
        return NSFetchRequest<Click>(entityName: entityName)
    }

    @NSManaged public var clickID: NSNumber
    @NSManaged public var timeStamp: Date?
    @NSManaged public var batch: Batch?
    @NSManaged public var point: Point?

}

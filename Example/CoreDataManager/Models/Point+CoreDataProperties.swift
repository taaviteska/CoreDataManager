//
//  Point+CoreDataProperties.swift
//  CoreDataManager_Example
//
//  Created by Nguyen Truong Luu on 12/19/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//
//

import Foundation
import CoreData


extension Point {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Point> {
        return NSFetchRequest<Point>(entityName: entityName)
    }

    @NSManaged public var id: NSNumber
    @NSManaged public var x: NSNumber?
    @NSManaged public var y: NSNumber?
    @NSManaged public var click: Click?

}

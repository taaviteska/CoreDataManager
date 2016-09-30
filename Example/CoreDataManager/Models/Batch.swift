//
//  Batch.swift
//  CoreDataManager
//
//  Created by Taavi Teska on 06/09/15.
//  Copyright (c) 2015 CocoaPods. All rights reserved.
//

import Foundation
import CoreData

open class Batch: NSManagedObject {

    @NSManaged open var name: String
    @NSManaged open var id: NSNumber
    @NSManaged open var clicks: NSSet

}

//
//  Batch.swift
//  CoreDataManager
//
//  Created by Taavi Teska on 06/09/15.
//  Copyright (c) 2015 CocoaPods. All rights reserved.
//

import Foundation
import CoreData

class Batch: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var id: NSNumber
    @NSManaged var clicks: NSSet

}

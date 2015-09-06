//
//  Batch.swift
//  CoreDataManager
//
//  Created by Taavi Teska on 06/09/15.
//  Copyright (c) 2015 CocoaPods. All rights reserved.
//

import Foundation
import CoreData

public class Batch: NSManagedObject {

    @NSManaged public var name: String
    @NSManaged public var id: NSNumber
    @NSManaged public var clicks: NSSet

}

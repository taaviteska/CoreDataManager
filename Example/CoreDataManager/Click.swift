//
//  Click.swift
//  CoreDataManager
//
//  Created by Taavi Teska on 06/09/15.
//  Copyright (c) 2015 CocoaPods. All rights reserved.
//

import Foundation
import CoreData

open class Click: NSManagedObject {

    @NSManaged open var clickID: NSNumber
    @NSManaged open var timeStamp: Date
    
    @NSManaged open var batch: Batch

}

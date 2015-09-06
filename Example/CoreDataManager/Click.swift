//
//  Click.swift
//  CoreDataManager
//
//  Created by Taavi Teska on 06/09/15.
//  Copyright (c) 2015 CocoaPods. All rights reserved.
//

import Foundation
import CoreData

public class Click: NSManagedObject {

    @NSManaged public var clickID: NSNumber
    @NSManaged public var timeStamp: NSDate
    
    @NSManaged public var batch: Batch

}

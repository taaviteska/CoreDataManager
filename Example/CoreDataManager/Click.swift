//
//  Click.swift
//  CoreDataManager
//
//  Created by Taavi Teska on 06/09/15.
//  Copyright (c) 2015 CocoaPods. All rights reserved.
//

import Foundation
import CoreData

class Click: NSManagedObject {

    @NSManaged var clickID: NSNumber
    @NSManaged var timeStamp: NSDate

}

//
//  NSManagedObject.swift
//  Pods
//
//  Created by Taavi Teska on 06/09/15.
//
//

import CoreData

public extension NSManagedObject {
    static var entityName: String {
        return NSStringFromClass(self).components(separatedBy: ".").last ?? ""
    }

    func delete() {
        managedObjectContext?.delete(self)
    }
    
    class func insert(into context: NSManagedObjectContext) -> Self? {
        return NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as? Self
    }
}

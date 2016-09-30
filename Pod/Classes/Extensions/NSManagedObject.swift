//
//  NSManagedObject.swift
//  Pods
//
//  Created by Taavi Teska on 06/09/15.
//
//

import CoreData


extension NSManagedObject {
    
    public func delete() {
        if let context = self.managedObjectContext {
            context.delete(self)
        }
    }
}

//
//  NSManagedObjectContext.swift
//  Pods
//
//  Created by Taavi Teska on 06/09/15.
//
//

import CoreData


extension NSManagedObjectContext {
    
    public func managerFor<T:NSManagedObject>(entity:T.Type) -> ManagedObjectManager<T> {
        return ManagedObjectManager(context: self)
    }
    
    public func save() -> NSError? {
        var error: NSError? = nil
        if self.hasChanges {
            self.save(&error)
        }
        
        return error
    }
}

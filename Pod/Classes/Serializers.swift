//
//  Serializers.swift
//  Pods
//
//  Created by Taavi Teska on 12/09/15.
//
//

import CoreData
import SwiftyJSON


public typealias CDMValidator = (_ data:JSON) -> JSON?


open class CDMSerializer<T:NSManagedObject> {
    
    open var identifiers = [String]()
    open var forceInsert = false
    open var insertMissing = true
    open var updateExisting = true
    open var deleteMissing = true
    open var mapping: [String: CDMAttribute]
    
    public init() {
        self.mapping = [String: CDMAttribute]()
    }
    
    open func getValidators() -> [CDMValidator] {
        return [CDMValidator]()
    }
    
    open func getGroupers() -> [NSPredicate] {
        return [NSPredicate]()
    }
    
    open func addAttributes(_ attributes: JSON, toObject object: NSManagedObject) {
        for (key, attribute) in self.mapping {
            var newValue: Any?
            if attribute.needsContext {
                if let context = object.managedObjectContext {
                    newValue = attribute.valueFrom(attributes, inContext: context)
                } else {
                    fatalError("Object has to have a managed object context")
                }
            } else {
                newValue = attribute.valueFrom(attributes)
            }
            object.setValue(newValue, forKey: key)
        }
    }
}




//
//  Serializers.swift
//  Pods
//
//  Created by Taavi Teska on 12/09/15.
//
//

import CoreData
import SwiftyJSON


public typealias CDMValidator = (data:JSON) -> JSON?


public class CDMSerializer<T:NSManagedObject> {
    
    public var identifiers = [String]()
    public var insertMissing = true
    public var updateExisting = true
    public var deleteMissing = true
    public var mapping = [String: CDMAttribute]()
    
    public init() {
    }
    
    public func getValidators() -> [CDMValidator] {
        return [CDMValidator]()
    }
    
    public func getGroupers() -> [NSPredicate] {
        return [NSPredicate]()
    }
    
    func addAttributes(attributes: JSON, toObject object: NSManagedObject) {
        for (key, attribute) in self.mapping {
            var newValue: AnyObject?
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




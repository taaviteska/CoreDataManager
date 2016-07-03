//
//  NSManagedObjectContext.swift
//  Pods
//
//  Created by Taavi Teska on 06/09/15.
//
//

import CoreData
import SwiftyJSON


extension NSManagedObjectContext {
    
    public func managerFor<T:NSManagedObject>(entity:T.Type) -> ManagedObjectManager<T> {
        return ManagedObjectManager(context: self)
    }
    
    public func saveIfChanged() throws {
        if self.hasChanges {
            try self.save()
        }
    }
    
    public func insert<T:NSManagedObject>(entity: T.Type, withJSON json: JSON, complete: ((NSError?) -> Void)? = nil) {
        let serializer = CDMSerializer<T>()
        serializer.forceInsert = true
        serializer.deleteMissing = false
        
        serializer.mapping = [String: CDMAttribute]()
        for attr in json.dictionary!.keys {
            serializer.mapping[attr] = CDMAttribute(attr)
        }
        
        self.syncData(json, withSerializer: serializer, complete: complete)
    }
    
    public func insertOrUpdate<T:NSManagedObject>(entity: T.Type, withJSON json: JSON, andIdentifiers identifiers: [String], complete: ((NSError?) -> Void)? = nil) {
        let serializer = CDMSerializer<T>()
        serializer.deleteMissing = false
        serializer.identifiers = identifiers
        
        serializer.mapping = [String: CDMAttribute]()
        for attr in json.dictionary!.keys {
            serializer.mapping[attr] = CDMAttribute(attr)
        }
        
        self.syncData(json, withSerializer: serializer, complete: complete)
    }
    
    public func syncData<T:NSManagedObject>(json: JSON, withSerializer serializer: CDMSerializer<T>, complete: ((NSError?) -> Void)? = nil) {
        self.performBlock({ () -> Void in
            do {
                try self.syncDataArray(json, withSerializer: serializer, andSave: true)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    complete?(nil)
                })
            } catch let error as NSError {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    complete?(error)
                })
            }
        })
    }
    
    func syncDataArray<T:NSManagedObject>(json: JSON, withSerializer serializer: CDMSerializer<T>, andSave save: Bool) throws -> Array<T> {
        
        if json == nil {
            return []
        }
        
        // Validate data
        var validData = json.array != nil ? json : JSON([json])
        
        for validator in serializer.getValidators() {
            var _dataArray = [JSON]()
            for (_, object) in validData {
                if let validObject = validator(data: object) where validObject.type != .Null {
                    _dataArray.append(validObject)
                }
            }
            validData = JSON(_dataArray)
        }
        
        if validData.isEmpty && !serializer.deleteMissing {
            return []
        }
        
        // MARK: Delete missing objects
        
        if serializer.deleteMissing {
            var currentKeys = Set<String>()
            
            for (_, attributes) in validData {
                var currentKey = ""
                for identifier in serializer.identifiers {
                    if let key: AnyObject = serializer.mapping[identifier]!.valueFrom(attributes) {
                        currentKey += "\(key)-"
                    }
                }
                currentKeys.insert(currentKey)
            }
            
            let existingObjects = self.managerFor(T).filter(NSCompoundPredicate(andPredicateWithSubpredicates: serializer.getGroupers())).array
            for existingObject in existingObjects {
                var objectKey = ""
                
                for identifier in serializer.identifiers {
                    if let key = existingObject.valueForKeyPath(identifier) {
                        objectKey += "\(key)-"
                    }
                }
                
                if !currentKeys.contains(objectKey) {
                    self.deleteObject(existingObject)
                }
            }
        }
        
        if save {
            try self.saveIfChanged()
        }
        
        
        // MARK: Update or insert objects
        
        var resultingObjects = [T]()
        
        for (_, attributes) in validData {
            if serializer.forceInsert {
                // TODO: Move insert logic to one place
                let object = NSEntityDescription.insertNewObjectForEntityForName(self.managerFor(T).entityName(), inManagedObjectContext: self) as! T
                serializer.addAttributes(attributes, toObject: object)
                resultingObjects.append(object)
            } else {
                var predicates = [NSPredicate]()
                
                for identifier in serializer.identifiers {
                    if let entityID = serializer.mapping[identifier]!.valueFrom(attributes) as? Int {
                        predicates.append(NSPredicate(format: "\(identifier) == %d", entityID))
                    } else if let entityID = serializer.mapping[identifier]!.valueFrom(attributes) as? String {
                        predicates.append(NSPredicate(format: "\(identifier) == %@", entityID))
                    }
                }
                
                predicates.appendContentsOf(serializer.getGroupers())
                let existingObjects = self.managerFor(T).filter(NSCompoundPredicate(andPredicateWithSubpredicates: predicates)).array
                
                if existingObjects.isEmpty {
                    if serializer.insertMissing {
                        let object = NSEntityDescription.insertNewObjectForEntityForName(self.managerFor(T).entityName(), inManagedObjectContext: self) as! T
                        serializer.addAttributes(attributes, toObject: object)
                        resultingObjects.append(object)
                    }
                } else {
                    for object in existingObjects {
                        if serializer.updateExisting {
                            serializer.addAttributes(attributes, toObject: object)
                        }
                        resultingObjects.append(object)
                    }
                }
            }
            
            if save {
                try self.save()
            }
        }
        
        return resultingObjects
    }
}

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
    
    public func managerFor<T:NSManagedObject>(_ entity:T.Type) -> ManagedObjectManager<T> {
        return ManagedObjectManager(context: self)
    }
    
    public func saveIfChanged() throws {
        if self.hasChanges {
            try self.save()
        }
    }
    
    public func insert<T:NSManagedObject>(_ entity: T.Type, withJSON json: JSON, complete: ((NSError?) -> Void)? = nil) {
        let serializer = CDMSerializer<T>()
        serializer.forceInsert = true
        serializer.deleteMissing = false
        
        serializer.mapping = [String: CDMAttribute]()
        for attr in json.dictionary!.keys {
            serializer.mapping[attr] = CDMAttribute(attr)
        }
        
        self.syncData(json, withSerializer: serializer, complete: complete)
    }
    
    public func insertOrUpdate<T:NSManagedObject>(_ entity: T.Type, withJSON json: JSON, andIdentifiers identifiers: [String], complete: ((NSError?) -> Void)? = nil) {
        let serializer = CDMSerializer<T>()
        serializer.deleteMissing = false
        serializer.identifiers = identifiers
        
        serializer.mapping = [String: CDMAttribute]()
        for attr in json.dictionary!.keys {
            serializer.mapping[attr] = CDMAttribute(attr)
        }
        
        self.syncData(json, withSerializer: serializer, complete: complete)
    }
    
    public func syncData<T>(_ json: JSON, withSerializer serializer: CDMSerializer<T>, complete: ((NSError?) -> Void)? = nil) {
        self.perform({ () -> Void in
            do {
                _ = try self.syncDataArray(json, withSerializer: serializer, andSave: true)
                
                DispatchQueue.main.async(execute: { () -> Void in
                    complete?(nil)
                })
            } catch let error as NSError {
                DispatchQueue.main.async(execute: { () -> Void in
                    complete?(error)
                })
            }
        })
    }
    
    func syncDataArray<T>(_ json: JSON, withSerializer serializer: CDMSerializer<T>, andSave save: Bool) throws -> Array<T> {
        
        if json == JSON.null {
            return []
        }
        
        // Validate data
        var validData = json.array != nil ? json : JSON([json])
        
        for validator in serializer.getValidators() {
            var _dataArray = [JSON]()
            for (_, object) in validData {
                if let validObject = validator(object) , validObject.type != .null {
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
                    if let key: Any = serializer.mapping[identifier]!.valueFrom(attributes) {
                        currentKey += "\(key)-"
                    }
                }
                currentKeys.insert(currentKey)
            }
            
            let existingObjects = self.managerFor(T.self).filter(NSCompoundPredicate(andPredicateWithSubpredicates: serializer.getGroupers())).array
            for existingObject in existingObjects {
                var objectKey = ""
                
                for identifier in serializer.identifiers {
                    if let key = existingObject.value(forKeyPath: identifier) {
                        objectKey += "\(key)-"
                    }
                }
                
                if !currentKeys.contains(objectKey) {
                    self.delete(existingObject)
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
                let object = NSEntityDescription.insertNewObject(forEntityName: self.managerFor(T.self).entityName(), into: self) as! T
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
                
                predicates.append(contentsOf: serializer.getGroupers())
                let existingObjects = self.managerFor(T.self).filter(NSCompoundPredicate(andPredicateWithSubpredicates: predicates)).array
                
                if existingObjects.isEmpty {
                    if serializer.insertMissing {
                        let object = NSEntityDescription.insertNewObject(forEntityName: self.managerFor(T.self).entityName(), into: self) as! T
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

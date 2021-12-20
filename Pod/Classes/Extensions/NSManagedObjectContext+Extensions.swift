//
//  NSManagedObjectContext.swift
//  Pods
//
//  Created by Taavi Teska on 06/09/15.
//
//

import CoreData
import SwiftyJSON

public extension NSManagedObjectContext {
    func managerFor<T: NSManagedObject>(_ entity: T.Type) -> ManagedObjectManager<T> {
        return ManagedObjectManager(context: self)
    }
    
    func saveIfChanged() throws {
        if self.hasChanges {
            try self.save()
        }
    }
    
    func insert<T: NSManagedObject>(_ entity: T.Type, withJSON json: JSON, complete: ((NSError?) -> Void)? = nil) {
        let serializer = CDMSerializer<T>()
        serializer.forceInsert = true
        serializer.deleteMissing = false
        
        serializer.mapping = [String: CDMAttribute]()
        if let dictionary = json.dictionary {
            for attr in dictionary.keys {
                serializer.mapping[attr] = CDMAttribute(attr)
            }
        }
        
        self.syncData(json, withSerializer: serializer, complete: complete)
    }
    
    func insertOrUpdate<T: NSManagedObject>(_ entity: T.Type, withJSON json: JSON, andIdentifiers identifiers: [String], complete: ((NSError?) -> Void)? = nil) {
        let serializer = CDMSerializer<T>()
        serializer.deleteMissing = false
        serializer.identifiers = identifiers
        
        serializer.mapping = [String: CDMAttribute]()
        if let dictionary = json.dictionary {
            for attr in dictionary.keys {
                serializer.mapping[attr] = CDMAttribute(attr)
            }
        }
        self.syncData(json, withSerializer: serializer, complete: complete)
    }
    
    func syncData<T>(_ json: JSON, withSerializer serializer: CDMSerializer<T>, complete: ((NSError?) -> Void)? = nil) {
        self.perform { () -> Void in
            do {
                _ = try self.syncDataArray(json, withSerializer: serializer, andSave: true)
                
                DispatchQueue.main.async { () -> Void in
                    complete?(nil)
                }
            } catch let error as NSError {
                DispatchQueue.main.async { () -> Void in
                    complete?(error)
                }
            }
        }
    }
    
    internal func syncDataArray<T>(_ json: JSON, withSerializer serializer: CDMSerializer<T>, andSave save: Bool) throws -> [T] {
        if json == JSON.null {
            return []
        }
        
        // Validate data
        var validData = json.array != nil ? json : JSON([json])
        
        for validator in serializer.getValidators() {
            var _dataArray = [JSON]()
            for (_, object) in validData {
                if let validObject = validator(object), validObject.type != .null {
                    _dataArray.append(validObject)
                }
            }
            validData = JSON(_dataArray)
        }
        
        if validData.isEmpty, !serializer.deleteMissing {
            return []
        }
        
        // MARK: Delete missing objects
        
        if serializer.deleteMissing {
            var currentKeys = Set<String>()
            
            for (_, jsonData) in validData {
                let objectKey = serializer.identifiers.compactMap { identifier in
                    if let key = serializer.mapping[identifier]?.valueFrom(jsonData) {
                        return "\(identifier):\(key)-"
                    }
                    return nil
                }.joined(separator: "")
                currentKeys.insert(objectKey)
            }
            
            var predicates: [NSPredicate] = serializer.parentPredicates()
            predicates.append(contentsOf: serializer.getGroupers())
            
            let existingObjects = managerFor(T.self).filter(NSCompoundPredicate(andPredicateWithSubpredicates: predicates)).array
            for existingObject in existingObjects {
                let objectKey = serializer.identifiers.compactMap { identifier in
                    if let key = existingObject.value(forKeyPath: identifier) {
                        return "\(identifier):\(key)-"
                    }
                    return nil
                }.joined(separator: "")
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
        
        for (_, jsonData) in validData {
            if serializer.forceInsert, let object = NSEntityDescription.insertNewObject(forEntityName: T.entityName, into: self) as? T {
                // TODO: Move insert logic to one place
                serializer.addAttributes(jsonData, toObject: object)
                resultingObjects.append(object)
            } else {
                var predicates: [NSPredicate] = serializer.parentPredicates()
                for identifier in serializer.identifiers {
                    if let entityID = serializer.mapping[identifier]?.valueFrom(jsonData) as? Int {
                        predicates.append(NSPredicate(format: "\(identifier) == %d", entityID))
                    } else if let entityID = serializer.mapping[identifier]?.valueFrom(jsonData) as? String {
                        predicates.append(NSPredicate(format: "\(identifier) == %@", entityID))
                    }
                }
                predicates.append(contentsOf: serializer.getGroupers())
                
                let existingObjects = self.managerFor(T.self).filter(NSCompoundPredicate(andPredicateWithSubpredicates: predicates)).array
                
                if existingObjects.isEmpty {
                    if serializer.insertMissing, let object = NSEntityDescription.insertNewObject(forEntityName: T.entityName, into: self) as? T {
                        serializer.addAttributes(jsonData, toObject: object)
                        resultingObjects.append(object)
                    }
                } else {
                    for object in existingObjects {
                        if serializer.updateExisting {
                            serializer.addAttributes(jsonData, toObject: object)
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

private extension CDMSerializer {
    func parentPredicates() -> [NSPredicate] {
        var predicates: [NSPredicate] = []
        
        var parentSerializer: CDMSerializerProtocol? = inverseRelationship?.parentSerializer
        var currentSerializer: CDMSerializerProtocol? = self
        var inverseRelationship: String = ""
        var parentJson = parentSerializer?.json
        while let serializer = parentSerializer {
            if let currentInverseRelationship = currentSerializer?.inverseRelationship?.keyPath {
                inverseRelationship += "\(currentInverseRelationship)."
                for identifier in serializer.identifiers {
                    let parentIdentifier = "\(inverseRelationship)\(identifier)"
                    if let key: Any = serializer.mapping[identifier]?.valueFrom(parentJson) {
                        predicates.append(NSPredicate(format: "\(parentIdentifier) == \(key)"))
                    }
                }
            }
            currentSerializer = parentSerializer
            parentSerializer = parentSerializer?.inverseRelationship?.parentSerializer
            parentJson = parentSerializer?.json
        }
        
        return predicates
    }
}

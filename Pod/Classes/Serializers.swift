//
//  Serializers.swift
//  Pods
//
//  Created by Taavi Teska on 12/09/15.
//
//

import CoreData
import SwiftyJSON

public typealias CDMValidator = (_ data: JSON) -> JSON?

open class InverseRelationship {
    public let keyPath: String?
    public let parentSerializer: CDMSerializerProtocol?
    
    public init(keyPath: String?, parentSerializer: CDMSerializerProtocol?) {
        self.keyPath = keyPath
        self.parentSerializer = parentSerializer
    }
}

public protocol CDMSerializerProtocol {
    var mapping: [String: CDMAttribute] { get set }
    var identifiers: [String] { get set }
    var inverseRelationship: InverseRelationship? { get set }
    var json: JSON? { get set }
}

open class CDMSerializer<T: NSManagedObject>: CDMSerializerProtocol {
    public var inverseRelationship: InverseRelationship?
    open var identifiers = [String]()
    open var forceInsert = false
    open var insertMissing = true
    open var updateExisting = true
    open var deleteMissing = true
    open var mapping: [String: CDMAttribute]
    public var json: JSON?

    public init(inverseRelationship: InverseRelationship? = nil) {
        self.mapping = [String: CDMAttribute]()
        self.inverseRelationship = inverseRelationship
    }

    open func getValidators() -> [CDMValidator] {
        return [CDMValidator]()
    }

    open func getGroupers() -> [NSPredicate] {
        return [NSPredicate]()
    }

    open func addAttributes(_ json: JSON, toObject object: NSManagedObject) {
        self.json = json
        for (key, attribute) in self.mapping {
            var newValue: Any?
            if attribute.needsContext {
                if let context = object.managedObjectContext {
                    newValue = attribute.valueFrom(json, inContext: context)
                } else {
                    fatalError("Object has to have a managed object context")
                }
            } else {
                newValue = attribute.valueFrom(json)
            }
            object.setValue(newValue, forKey: key)
        }
    }
}

//
//  Attributes.swift
//  Pods
//
//  Created by Taavi Teska on 13/09/15.
//
//

import CoreData
import SwiftyJSON


open class CDMAttribute {
    
    fileprivate var key:[JSONSubscriptType]
    
    open var needsContext = false
    
    public init(_ key: [JSONSubscriptType]) {
        self.key = key
    }
    
    public convenience init(_ args: JSONSubscriptType...) {
        self.init(args)
    }
    
    open func valueAsJSON(_ attributes: JSON? = nil) -> JSON? {
        return attributes?[key]
    }
    
    open func valueFrom(_ attributes: JSON? = nil) -> Any? {
        return self.valueAsJSON(attributes)?.object
    }
    
    open func valueFrom(_ attributes: JSON? = nil, inContext context: NSManagedObjectContext) -> Any? {
        fatalError("Attributes which don't need context need to use valueFrom(attributes: JSON?)")
    }
}


open class CDMAttributeString:CDMAttribute {
    override open func valueFrom(_ attributes: JSON? = nil) -> Any? {
        return self.valueAsJSON(attributes)?.string
    }
}


open class CDMAttributeBool:CDMAttribute {
    override open func valueFrom(_ attributes: JSON? = nil) -> Any? {
        return self.valueAsJSON(attributes)?.bool
    }
}


open class CDMAttributeInt:CDMAttribute {
    override open func valueFrom(_ attributes: JSON? = nil) -> Any? {
        return self.valueAsJSON(attributes)?.int
    }
}


open class CDMAttributeNumber:CDMAttribute {
    override open func valueFrom(_ attributes: JSON? = nil) -> Any? {
        return self.valueAsJSON(attributes)?.number
    }
}


open class CDMAttributeDouble:CDMAttribute {
    override open func valueFrom(_ attributes: JSON? = nil) -> Any? {
        return self.valueAsJSON(attributes)?.double
    }
}


open class CDMAttributeFloat:CDMAttribute {
    override open func valueFrom(_ attributes: JSON? = nil) -> Any? {
        return self.valueAsJSON(attributes)?.float
    }
}


open class CDMAttributeISODate:CDMAttributeString {
    override open func valueFrom(_ attributes: JSON? = nil) -> Any? {
        if let dateString = super.valueFrom(attributes) as? String , dateString != "" {
            let formats = ["yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ", "yyyy-MM-dd'T'HH:mm:ssZZZZZ"]
            for format in formats {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }
            return nil
        }
        return nil
    }
}


open class CDMAttributeToMany<T:NSManagedObject>:CDMAttribute {
    
    fileprivate var serializerCallback: (JSON) -> (CDMSerializer<T>)
    
    public init(_ key: [JSONSubscriptType], serializerCallback: @escaping (JSON) -> (CDMSerializer<T>)) {
        self.serializerCallback = serializerCallback
        super.init(key)
        
        self.needsContext = true
    }
    
    override open func valueFrom(_ attributes: JSON? = nil) -> Any? {
        fatalError("Managed object attributes need to have a context where to take the value")
    }
    
    override open func valueFrom(_ attributes: JSON? = nil, inContext context: NSManagedObjectContext) -> Any? {
        if let data = self.valueAsJSON(attributes) {
            let serializer = self.serializerCallback(attributes!)
            do {
                return NSSet(array: try context.syncDataArray(data, withSerializer: serializer, andSave: false))
            } catch {
                return nil
            }
        }
        
        return nil
    }
}


open class CDMAttributeToOne<T:NSManagedObject>:CDMAttributeToMany<T> {
    
    public override init(_ key: [JSONSubscriptType], serializerCallback: @escaping (JSON) -> (CDMSerializer<T>)) {
        super.init(key, serializerCallback: serializerCallback)
    }
    
    override open func valueFrom(_ attributes: JSON? = nil, inContext context: NSManagedObjectContext) -> Any? {
        
        if let objects = super.valueFrom(attributes, inContext: context) as? NSSet , objects.count == 1 {
            return objects.allObjects[0]
        }
        
        return nil
    }
}

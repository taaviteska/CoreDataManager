//
//  Attributes.swift
//  Pods
//
//  Created by Taavi Teska on 13/09/15.
//
//

import CoreData
import SwiftyJSON


public class CDMAttribute {
    
    private var key:[JSONSubscriptType]
    
    public var needsContext = false
    
    public init(_ key: [JSONSubscriptType]) {
        self.key = key
    }
    
    public convenience init(_ args: JSONSubscriptType...) {
        self.init(args)
    }
    
    public func valueAsJSON(attributes: JSON? = nil) -> JSON? {
        return attributes?[key]
    }
    
    public func valueFrom(attributes: JSON? = nil) -> AnyObject? {
        return self.valueAsJSON(attributes)?.object
    }
    
    public func valueFrom(attributes: JSON? = nil, inContext context: NSManagedObjectContext) -> AnyObject? {
        fatalError("Attributes which don't need context need to use valueFrom(attributes: JSON?)")
    }
}


public class CDMAttributeString:CDMAttribute {
    override public func valueFrom(attributes: JSON? = nil) -> AnyObject? {
        return self.valueAsJSON(attributes)?.string
    }
}


public class CDMAttributeNumber:CDMAttribute {
    override public func valueFrom(attributes: JSON? = nil) -> AnyObject? {
        return self.valueAsJSON(attributes)?.number
    }
}


public class CDMAttributeDouble:CDMAttribute {
    override public func valueFrom(attributes: JSON? = nil) -> AnyObject? {
        return self.valueAsJSON(attributes)?.double
    }
}


public class CDMAttributeISODate:CDMAttributeString {
    override public func valueFrom(attributes: JSON? = nil) -> AnyObject? {
        if let dateString = super.valueFrom(attributes) as? String where dateString != "" {
            let dateFormatter = NSDateFormatter()
            
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
            return dateFormatter.dateFromString(dateString)
        }
        
        return nil
    }
}


public class CDMAttributeToMany<T:NSManagedObject>:CDMAttribute {
    
    private var serializer:CDMSerializer<T>!
    
    public init(_ key: [JSONSubscriptType], serializer: CDMSerializer<T>) {
        super.init(key)
        self.serializer = serializer
        self.needsContext = true
    }
    
    override public func valueFrom(attributes: JSON? = nil) -> AnyObject? {
        fatalError("Managed object attributes need to have a context where to take the value")
    }
    
    override public func valueFrom(attributes: JSON? = nil, inContext context: NSManagedObjectContext) -> AnyObject? {
        if let data = self.valueAsJSON(attributes) {
            do {
                return NSSet(array: try context.syncDataArray(data, withSerializer: self.serializer, andSave: false))
            } catch {
                return nil
            }
        }
        
        return nil
    }
}


public class CDMAttributeToOne<T:NSManagedObject>:CDMAttributeToMany<T> {
    
    override public func valueFrom(attributes: JSON? = nil, inContext context: NSManagedObjectContext) -> AnyObject? {
        
        if let objects = super.valueFrom(attributes, inContext: context) as? NSSet where objects.count == 1 {
            return objects.allObjects[0]
        }
        
        return nil
    }
}

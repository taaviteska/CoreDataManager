//
//  ManagedObjectManager.swift
//  Pods
//
//  Created by Taavi Teska on 05/09/15.
//
//

import CoreData

open class ManagedObjectManager<T:NSManagedObject> {
    
    fileprivate var context: NSManagedObjectContext!
    
    fileprivate var managerPredicate: NSPredicate?
    fileprivate var managerFetchLimit: Int?
    fileprivate var managerSortDescriptors = [NSSortDescriptor]()
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    
    // MARK: Entity
    
    open func entityName() -> String {
        
        return NSStringFromClass(T.self).components(separatedBy: ".").last!
        
    }
    
}

//MARK: - Filtering

extension ManagedObjectManager {
    
    public func filter(format predicateFormat: String, _ args: CVarArg...) -> ManagedObjectManager<T> {
        
        return withVaList(args) {
            self.filter(format: predicateFormat, arguments: $0)
        }
        
    }
    
    public func filter(format predicateFormat: String, argumentArray arguments: [AnyObject]?) -> ManagedObjectManager<T> {
        
        return self.filter(NSPredicate(format: predicateFormat, argumentArray: arguments))
        
    }
    
    public func filter(format predicateFormat: String, arguments argList: CVaListPointer) -> ManagedObjectManager<T> {
        
        return self.filter(NSPredicate(format: predicateFormat, arguments: argList))
        
    }
    
    public func filter(_ predicate: NSPredicate) -> ManagedObjectManager<T> {
        
        if let currentPredicate = managerPredicate {
            self.managerPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [currentPredicate, predicate])
        } else {
            self.managerPredicate = predicate
        }
        
        return self
        
    }
    
}

//MARK: - Ordering

extension ManagedObjectManager {
    
    public func orderBy(_ argument: String) -> ManagedObjectManager<T> {
        
        let isAscending = !argument.hasPrefix("-")
        let key = isAscending ? argument : String(argument[argument.index(argument.startIndex, offsetBy: 1)...])
        
        self.managerSortDescriptors.append(NSSortDescriptor(key: key, ascending: isAscending))
        
        return self
        
    }
    
    public func orderBy(_ arguments: [String]) -> ManagedObjectManager<T> {
        
        for arg in arguments {
            _ = self.orderBy(arg)
        }
        
        return self
        
    }
    
}

//MARK: - Aggregation

extension ManagedObjectManager {
    
    public var count: Int? {
        get {
            let fetchRequest = self.fetchRequest()
            
            return try? self.context.count(for: fetchRequest)
        }
    }
    
    public func min(_ keyPath: String) -> Any? {
        return self.aggregate("min", forKeyPath: keyPath)
    }
    
    public func max(_ keyPath: String) -> Any? {
        return self.aggregate("max", forKeyPath: keyPath)
    }
    
    public func sum(_ keyPath: String) -> Any? {
        return self.aggregate("sum", forKeyPath: keyPath)
    }
    
    public func aggregate(_ functionName: String, forKeyPath keyPath: String) -> Any? {
        let expression = NSExpression(forFunction: functionName + ":", arguments: [NSExpression(forKeyPath: keyPath)])
        
        let expressionName = functionName + keyPath
        let expressionDescription = NSExpressionDescription()
        expressionDescription.name = expressionName
        expressionDescription.expression = expression
        
        var entityDescription = NSEntityDescription.entity(forEntityName: self.entityName(), in: self.context)!
        var keyPathArray = keyPath.components(separatedBy: ".")
        let lastKey = keyPathArray.removeLast()
        
        for key in keyPathArray {
            let relationshipDesc = entityDescription.propertiesByName[key] as! NSRelationshipDescription
            entityDescription = relationshipDesc.destinationEntity!
        }
        let entityAttributeDesc = entityDescription.attributesByName[lastKey]!
        expressionDescription.expressionResultType = entityAttributeDesc.attributeType
        
        // Since we are changing expressionResultType we also need to check if there are any objects returned
        
        var fetchRequest = self.fetchRequest()
        guard let objectCount = self.count else {
            return nil
        }
        
        if objectCount == 0 {
            return nil
        }
        
        fetchRequest = self.fetchRequest()
        fetchRequest.resultType = NSFetchRequestResultType.dictionaryResultType
        fetchRequest.propertiesToFetch = [expressionDescription]
        
        do {
            let results = try self.context.fetch(fetchRequest) as [AnyObject]
            if results.count > 0 {
                return results[0].value(forKey: expressionName)
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
}

//MARK: - Fetching

extension ManagedObjectManager {
    
    public var array:[T] {
        get {
            return self.resultsWithPredicate(self.managerPredicate, andSortDescriptors: self.managerSortDescriptors, withFetchLimit: self.managerFetchLimit)
        }
    }
    
    public var first: T? {
        get {
            return self.resultsWithPredicate(self.managerPredicate, andSortDescriptors: self.managerSortDescriptors, withFetchLimit: 1).first
        }
    }
    
    public var last: T? {
        get {
            var sortDescriptors = [NSSortDescriptor]()
            for sortDescriptor in self.managerSortDescriptors {
                sortDescriptors.append(NSSortDescriptor(key: sortDescriptor.key!, ascending: !sortDescriptor.ascending))
            }
            return self.resultsWithPredicate(self.managerPredicate, andSortDescriptors: sortDescriptors, withFetchLimit: 1).first
        }
    }
    
}

//MARK: - Deleting

extension ManagedObjectManager {
    
    public func delete() -> Int {
        let results = self.resultsWithPredicate(self.managerPredicate, andSortDescriptors: self.managerSortDescriptors, withFetchLimit: self.managerFetchLimit)
        let resultsCount = results.count
        
        for result in results {
            result.delete()
        }
        
        return resultsCount
    }
    
}

//MARK: - Private methods

extension ManagedObjectManager {
    
    
    // MARK: Fetch requests
    
    fileprivate func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        
        return self.fetchRequestWithPredicate(self.managerPredicate, andSortDescriptors: self.managerSortDescriptors, withFetchLimit: self.managerFetchLimit)
        
    }
    
    fileprivate func fetchRequestWithPredicate(_ predicate: NSPredicate?, andSortDescriptors sortDescriptors: [NSSortDescriptor], withFetchLimit limit: Int?) -> NSFetchRequest<NSFetchRequestResult> {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName())
        
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        if let fetchLimit = limit {
            fetchRequest.fetchLimit = fetchLimit
        }
        
        return fetchRequest
        
    }
    
    
    // MARK: Results
    
    fileprivate func results() -> [T] {
        
        do {
            return try self.context.fetch(self.fetchRequest()) as! [T]
        } catch {
            return []
        }
        
    }
    
    fileprivate func resultsWithPredicate(_ predicate: NSPredicate?, andSortDescriptors sortDescriptors: [NSSortDescriptor], withFetchLimit limit: Int?) -> [T] {
        
        let fetchRequest = self.fetchRequestWithPredicate(predicate, andSortDescriptors: sortDescriptors, withFetchLimit: limit)
        
        do {
            return try self.context.fetch(fetchRequest) as! [T]
        } catch {
            return []
        }
        
    }
    
}

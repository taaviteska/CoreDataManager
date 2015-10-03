//
//  ManagedObjectManager.swift
//  Pods
//
//  Created by Taavi Teska on 05/09/15.
//
//

import CoreData

public class ManagedObjectManager<T:NSManagedObject> {
    
    private var context: NSManagedObjectContext!
    
    private var managerPredicate: NSPredicate?
    private var managerFetchLimit: Int?
    private var managerSortDescriptors = [NSSortDescriptor]()
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    
    // MARK: Entity
    
    public func entityName() -> String {
        
        return NSStringFromClass(T).componentsSeparatedByString(".").last!
        
    }
    
}

//MARK: - Filtering

extension ManagedObjectManager {
    
    public func filter(format predicateFormat: String, _ args: CVarArgType...) -> ManagedObjectManager<T> {
        
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
    
    public func filter(predicate: NSPredicate) -> ManagedObjectManager<T> {
        
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
    
    public func orderBy(argument: String) -> ManagedObjectManager<T> {
        
        let isAscending = !argument.hasPrefix("-")
        let key = isAscending ? argument : argument.substringFromIndex(argument.startIndex.advancedBy(1))
        
        self.managerSortDescriptors.append(NSSortDescriptor(key: key, ascending: isAscending))
        
        return self
        
    }
    
    public func orderBy(arguments: [String]) -> ManagedObjectManager<T> {
        
        for arg in arguments {
            self.orderBy(arg)
        }
        
        return self
        
    }
    
}

//MARK: - Aggregation

extension ManagedObjectManager {
    
    public var count: Int {
        get {
            let fetchRequest = self.fetchRequest()
            
            var error: NSError?
            return self.context.countForFetchRequest(fetchRequest, error: &error)
        }
    }
    
    public func min(keyPath: String) -> AnyObject? {
        return self.aggregate("min", forKeyPath: keyPath)
    }
    
    public func max(keyPath: String) -> AnyObject? {
        return self.aggregate("max", forKeyPath: keyPath)
    }
    
    public func sum(keyPath: String) -> AnyObject? {
        return self.aggregate("sum", forKeyPath: keyPath)
    }
    
    public func aggregate(functionName: String, forKeyPath keyPath: String) -> AnyObject? {
        let expression = NSExpression(forFunction: functionName.stringByAppendingString(":"), arguments: [NSExpression(forKeyPath: keyPath)])
        
        let expressionName = functionName + keyPath
        let expressionDescription = NSExpressionDescription()
        expressionDescription.name = expressionName
        expressionDescription.expression = expression
        
        var entityDescription = NSEntityDescription.entityForName(self.entityName(), inManagedObjectContext: self.context)!
        var keyPathArray = keyPath.componentsSeparatedByString(".")
        let lastKey = keyPathArray.removeLast()
        
        for key in keyPathArray {
            let relationshipDesc = entityDescription.propertiesByName[key] as! NSRelationshipDescription
            entityDescription = relationshipDesc.destinationEntity!
        }
        let entityAttributeDesc = entityDescription.attributesByName[lastKey]!
        expressionDescription.expressionResultType = entityAttributeDesc.attributeType
        
        // Since we are changing expressionResultType we also need to check if there are any objects returned
        
        var fetchRequest = self.fetchRequest()
        var error: NSError?
        let objectCount = self.context.countForFetchRequest(fetchRequest, error: &error)
        if objectCount == 0 || error != nil {
            return nil
        }
        
        fetchRequest = self.fetchRequest()
        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        fetchRequest.propertiesToFetch = [expressionDescription]
        
        do {
            let results = try self.context.executeFetchRequest(fetchRequest)
            if results.count > 0 {
                return results[0].valueForKey(expressionName)
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
    
    private func fetchRequest() -> NSFetchRequest {
        
        return self.fetchRequestWithPredicate(self.managerPredicate, andSortDescriptors: self.managerSortDescriptors, withFetchLimit: self.managerFetchLimit)
        
    }
    
    private func fetchRequestWithPredicate(predicate: NSPredicate?, andSortDescriptors sortDescriptors: [NSSortDescriptor], withFetchLimit limit: Int?) -> NSFetchRequest {
        
        let fetchRequest = NSFetchRequest(entityName: self.entityName())
        
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        if let fetchLimit = limit {
            fetchRequest.fetchLimit = fetchLimit
        }
        
        return fetchRequest
        
    }
    
    
    // MARK: Results
    
    private func results() -> [T] {
        
        do {
            return try self.context.executeFetchRequest(self.fetchRequest()) as! [T]
        } catch {
            return []
        }
        
    }
    
    private func resultsWithPredicate(predicate: NSPredicate?, andSortDescriptors sortDescriptors: [NSSortDescriptor], withFetchLimit limit: Int?) -> [T] {
        
        let fetchRequest = self.fetchRequestWithPredicate(predicate, andSortDescriptors: sortDescriptors, withFetchLimit: limit)
        
        do {
            return try self.context.executeFetchRequest(fetchRequest) as! [T]
        } catch {
            return []
        }
        
    }
    
}

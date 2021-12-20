//
//  ManagedObjectManager.swift
//  Pods
//
//  Created by Taavi Teska on 05/09/15.
//
//

import CoreData

open class ManagedObjectManager<T: NSManagedObject> {
    fileprivate let context: NSManagedObjectContext
    
    fileprivate var managerPredicate: NSPredicate?
    fileprivate var managerFetchLimit: Int?
    fileprivate var managerSortDescriptors = [NSSortDescriptor]()
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    open func entityName() -> String {
        return T.entityName
    }
}

// MARK: - Filtering

public extension ManagedObjectManager {
    func filter(format predicateFormat: String, _ args: CVarArg...) -> ManagedObjectManager<T> {
        return withVaList(args) {
            filter(format: predicateFormat, arguments: $0)
        }
    }
    
    func filter(format predicateFormat: String, argumentArray arguments: [AnyObject]?) -> ManagedObjectManager<T> {
        return filter(NSPredicate(format: predicateFormat, argumentArray: arguments))
    }
    
    func filter(format predicateFormat: String, arguments argList: CVaListPointer) -> ManagedObjectManager<T> {
        return filter(NSPredicate(format: predicateFormat, arguments: argList))
    }
    
    func filter(_ predicate: NSPredicate) -> ManagedObjectManager<T> {
        if let currentPredicate = managerPredicate {
            managerPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [currentPredicate, predicate])
        } else {
            managerPredicate = predicate
        }
        
        return self
    }
}

// MARK: - Ordering

public extension ManagedObjectManager {
    func orderBy(_ argument: String) -> ManagedObjectManager<T> {
        let isAscending = !argument.hasPrefix("-")
        let key = isAscending ? argument : String(argument[argument.index(argument.startIndex, offsetBy: 1)...])
        managerSortDescriptors.append(NSSortDescriptor(key: key, ascending: isAscending))
        return self
    }
    
    func orderBy(_ arguments: [String]) -> ManagedObjectManager<T> {
        for arg in arguments {
            _ = orderBy(arg)
        }
        
        return self
    }
}

// MARK: - Aggregation

public extension ManagedObjectManager {
    var count: Int? {
        let fetchRequest = createFetchRequest()
        return try? context.count(for: fetchRequest)
    }
    
    func min(_ keyPath: String) -> Any? {
        return aggregate("min", forKeyPath: keyPath)
    }
    
    func max(_ keyPath: String) -> Any? {
        return aggregate("max", forKeyPath: keyPath)
    }
    
    func sum(_ keyPath: String) -> Any? {
        return aggregate("sum", forKeyPath: keyPath)
    }
    
    func average(_ keyPath: String) -> Any? {
        return aggregate("average", forKeyPath: keyPath)
    }
    
    func aggregate(_ functionName: String, forKeyPath keyPath: String) -> Any? {
        let expression = NSExpression(forFunction: functionName + ":", arguments: [NSExpression(forKeyPath: keyPath)])
        
        let expressionName = functionName + keyPath
        let expressionDescription = NSExpressionDescription()
        expressionDescription.name = expressionName
        expressionDescription.expression = expression
        
        guard var entityDescription = NSEntityDescription.entity(forEntityName: self.entityName(), in: context) else { return nil }
        
        var keyPathArray = keyPath.components(separatedBy: ".")
        let lastKey = keyPathArray.removeLast()
        
        for key in keyPathArray {
            if let destinationEntity = (entityDescription.propertiesByName[key] as? NSRelationshipDescription)?.destinationEntity {
                entityDescription = destinationEntity
            }
        }
        if let entityAttributeDesc = entityDescription.attributesByName[lastKey] {
            expressionDescription.expressionResultType = entityAttributeDesc.attributeType
        }
        
        // Since we are changing expressionResultType we also need to check if there are any objects returned
        
        let fetchRequest = createFetchRequest()
        guard let objectCount = count, objectCount > 0 else { return nil }
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.propertiesToFetch = [expressionDescription]
        
        do {
            let results = try context.fetch(fetchRequest) as [AnyObject]
            return results.first?.value(forKey: expressionName)
        } catch {
            return nil
        }
    }
}

// MARK: - Fetching

public extension ManagedObjectManager {
    var array: [T] {
        return resultsWithPredicate(managerPredicate, andSortDescriptors: managerSortDescriptors, withFetchLimit: managerFetchLimit)
    }
    
    var first: T? {
        return resultsWithPredicate(managerPredicate, andSortDescriptors: managerSortDescriptors, withFetchLimit: 1).first
    }
    
    var last: T? {
        var sortDescriptors = [NSSortDescriptor]()
        for sortDescriptor in managerSortDescriptors {
            sortDescriptors.append(NSSortDescriptor(key: sortDescriptor.key!, ascending: !sortDescriptor.ascending))
        }
        return resultsWithPredicate(managerPredicate, andSortDescriptors: sortDescriptors, withFetchLimit: 1).first
    }
}

// MARK: - Deleting

public extension ManagedObjectManager {
    @discardableResult
    func delete() -> Int {
        let results = resultsWithPredicate(managerPredicate, andSortDescriptors: managerSortDescriptors, withFetchLimit: managerFetchLimit)
        let resultsCount = results.count
        
        for result in results {
            result.delete()
        }
        
        return resultsCount
    }
}

// MARK: - Private methods

private extension ManagedObjectManager {
    // MARK: Fetch requests
    
    func createFetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return fetchRequestWithPredicate(managerPredicate, andSortDescriptors: managerSortDescriptors, withFetchLimit: managerFetchLimit)
    }
    
    func fetchRequestWithPredicate(_ predicate: NSPredicate?, andSortDescriptors sortDescriptors: [NSSortDescriptor], withFetchLimit limit: Int?) -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName())
        
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        if let fetchLimit = limit {
            fetchRequest.fetchLimit = fetchLimit
        }
        
        return fetchRequest
    }
    
    // MARK: Results
    
    func results() -> [T] {
        return (try? context.fetch(createFetchRequest()) as? [T]) ?? []
    }
    
    func resultsWithPredicate(_ predicate: NSPredicate?, andSortDescriptors sortDescriptors: [NSSortDescriptor], withFetchLimit limit: Int?) -> [T] {
        let fetchRequest = fetchRequestWithPredicate(predicate, andSortDescriptors: sortDescriptors, withFetchLimit: limit)
        return (try? context.fetch(fetchRequest) as? [T]) ?? []
    }
}

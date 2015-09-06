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
            self.managerPredicate = NSCompoundPredicate.andPredicateWithSubpredicates([currentPredicate, predicate])
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
        let key = isAscending ? argument : argument.substringFromIndex(advance(argument.startIndex, 1))
        
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
            let fetchRequest = self.fetchRequestWithPredicate(self.managerPredicate, andSortDescriptors: self.managerSortDescriptors, withFetchLimit: self.managerFetchLimit)
            
            var error: NSError?
            return self.context.countForFetchRequest(fetchRequest, error: &error)
        }
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
        var results = self.resultsWithPredicate(self.managerPredicate, andSortDescriptors: self.managerSortDescriptors, withFetchLimit: self.managerFetchLimit)
        let resultsCount = results.count
        
        for result in results {
            result.delete()
        }
        
        return resultsCount
    }
    
}

//MARK: - Private methods

extension ManagedObjectManager {
    
    private func fetchRequestWithPredicate(predicate: NSPredicate?, andSortDescriptors sortDescriptors: [NSSortDescriptor], withFetchLimit limit: Int?) -> NSFetchRequest {
        
        let entityName = NSStringFromClass(T).componentsSeparatedByString(".").last!
        let fetchRequest = NSFetchRequest(entityName: entityName)
        
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        if let fetchLimit = limit {
            fetchRequest.fetchLimit = fetchLimit
        }
        
        return fetchRequest
        
    }
    
    private func resultsWithPredicate(predicate: NSPredicate?, andSortDescriptors sortDescriptors: [NSSortDescriptor], withFetchLimit limit: Int?) -> [T] {
        
        let fetchRequest = self.fetchRequestWithPredicate(predicate, andSortDescriptors: sortDescriptors, withFetchLimit: limit)
        
        var error:NSError?
        var results = self.context.executeFetchRequest(fetchRequest, error: &error) as! [T]
        
        return results
        
    }
    
}

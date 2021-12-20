//
//  CoreDataManager.swift
//  Pods
//
//  Created by Taavi Teska on 05/09/15.
//
//

import CoreData

open class CoreDataManager: NSObject {
    public static let sharedInstance = CoreDataManager()
    
    open fileprivate(set) var modelName: String?
    open fileprivate(set) var databaseURL: URL?
    
    public var persistentContainer: NSPersistentContainer {
        guard let privatePersistentContainer = privatePersistentContainer else {
            fatalError("CoreDataManager not set up. Use CoreDataManager.setupWithModel() or CoreDataManager.setupInMemoryWithModel()")
        }
        return privatePersistentContainer
    }

    public private(set) var privatePersistentContainer: NSPersistentContainer?
    
    override public init() {
        super.init()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Lazy contexts
    
    open lazy var mainContext: NSManagedObjectContext = {
        return getMainManagedObjectContext()
    }()
    
    open lazy var backgroundContext: NSManagedObjectContext = {
        return getBackgroundManagedObjectContext()
    }()
    
    // MARK: Other lazy variables
    
    fileprivate lazy var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count - 1]
    }()
}

// MARK: - Setup

public extension CoreDataManager {
    func setupWithModel(_ modelName: String) {
        setupWithModel(modelName, andFileName: modelName + ".sqlite")
    }
    
    func setupWithModel(_ modelName: String, andFileName fileName: String) {
        let url = applicationDocumentsDirectory.appendingPathComponent(fileName)
        setupWithModel(modelName, andDatabaseURL: url)
    }
    
    func setupWithModel(_ modelName: String, andDatabaseURL url: URL) {
        self.modelName = modelName
        self.databaseURL = url
        setupPersistentContainer(modelName: modelName, databaseURL: url)
    }
    
    func setupInMemoryWithModel(_ modelName: String) {
        self.modelName = modelName
        
        setupInMemoryPersistentContainer(modelName: modelName)
    }
}

// MARK: - Private

private extension CoreDataManager {
    func getMainManagedObjectContext() -> NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func getBackgroundManagedObjectContext() -> NSManagedObjectContext {
        let backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        backgroundContext.automaticallyMergesChangesFromParent = true
        return backgroundContext
    }

    func setupPersistentContainer(modelName: String, databaseURL: URL) {
        let container = NSPersistentContainer(name: modelName)
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.persistentStoreDescriptions = [getPersistentStoreDescription(databaseURL: databaseURL)]
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                debugPrint("Unresolved error \(error), \(error.userInfo)")
            }
        })
        privatePersistentContainer = container
    }
    
    func setupInMemoryPersistentContainer(modelName: String) {
        let container = NSPersistentContainer(name: modelName)
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.persistentStoreDescriptions = [getMemoryStoreDescription()]
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                debugPrint("Unresolved error \(error), \(error.userInfo)")
            }
        })
        privatePersistentContainer = container
    }
    
    func getPersistentStoreDescription(databaseURL: URL) -> NSPersistentStoreDescription {
        let storeDescription = NSPersistentStoreDescription(url: databaseURL)
        storeDescription.type = NSSQLiteStoreType
        storeDescription.shouldInferMappingModelAutomatically = true
        storeDescription.shouldMigrateStoreAutomatically = true
        return storeDescription
    }
    
    func getMemoryStoreDescription() -> NSPersistentStoreDescription {
        let storeDescription = NSPersistentStoreDescription()
        storeDescription.type = NSInMemoryStoreType
        storeDescription.shouldInferMappingModelAutomatically = true
        storeDescription.shouldMigrateStoreAutomatically = true
        return storeDescription
    }
}

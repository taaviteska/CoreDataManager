//
//  CoreDataManager.swift
//  Pods
//
//  Created by Taavi Teska on 05/09/15.
//
//

import CoreData


open class CoreDataManager:NSObject {
    
    open static let sharedInstance = CoreDataManager()
    
    fileprivate(set) open var modelName: String?
    fileprivate(set) open var databaseURL: URL?
    
    fileprivate var storeCoordinator: NSPersistentStoreCoordinator?
    
    override public init(){
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(CoreDataManager.contextDidSaveContext(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: Lazy contexts
    
    open lazy var mainContext: NSManagedObjectContext = {
        self.getManagedObjectContextWithType(NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        }()
    
    open lazy var backgroundContext: NSManagedObjectContext = {
        self.getManagedObjectContextWithType(NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        }()
    
    
    // MARK: Other lazy variables
    
    fileprivate lazy var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
        }()
    
    fileprivate lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        if let modelName = self.modelName {
            if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") {
                if let model = NSManagedObjectModel(contentsOf: modelURL) {
                    return model
                }
                
                fatalError("Couldn't find the managed object model with name \(modelName)\nChecked url: \(modelURL)")
            }
            
            fatalError("Couldn't find the managed object model with name \(modelName) in main bundle")
        }
        
        fatalError("CoreDataManager not set up. Use CoreDataManager.setupWithModel() or CoreDataManager.setupInMemoryWithModel()")
        }()
}


// MARK: - Setup

extension CoreDataManager {
    
    public func setupWithModel(_ model: String) {
        self.setupWithModel(model, andFileName: model + ".sqlite")
    }
    
    public func setupWithModel(_ model: String, andFileName fileName: String) {
        let url = self.applicationDocumentsDirectory.appendingPathComponent(fileName)
        self.setupWithModel(model, andFileURL: url)
    }
    
    public func setupWithModel(_ model: String, andFileURL url: URL) {
        self.modelName = model
        self.databaseURL = url
        
        self.setupPersistentStoreCoordinator()
    }
    
    public func setupInMemoryWithModel(_ model: String) {
        self.modelName = model
        
        self.setupInMemoryStoreCoordinator()
    }
    
}


// MARK: - Context saving notifications

extension CoreDataManager {
    
    // call back function by saveContext, support multi-thread
    @objc func contextDidSaveContext(_ notification: Notification) {
        let sender = notification.object as! NSManagedObjectContext
        if sender === self.mainContext {
            self.backgroundContext.perform {
                self.backgroundContext.mergeChanges(fromContextDidSave: notification)
            }
        } else if sender === self.backgroundContext {
            self.mainContext.perform {
                self.mainContext.mergeChanges(fromContextDidSave: notification)
            }
        }
    }
}


// MARK: - Private

extension CoreDataManager {

    fileprivate func getManagedObjectContextWithType(_ type: NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
        if let coordinator = self.storeCoordinator {
            let managedObjectContext = NSManagedObjectContext(concurrencyType: type)
            managedObjectContext.persistentStoreCoordinator = coordinator
            return managedObjectContext
        } else {
            fatalError("Store coordinator not set up. Use one of the CoreDataManager.setup() methods")
        }
    }
    
    // The persistent store coordinator for the application. This implementation creates a coordinator, having added the store for the application to it.
    fileprivate func setupPersistentStoreCoordinator() {
        if self.storeCoordinator != nil {
            return
        }
        
        let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        if let databaseURL = self.databaseURL {
            
            do {
                let options: [AnyHashable: Any] = [
                    NSMigratePersistentStoresAutomaticallyOption : true,
                    NSInferMappingModelAutomaticallyOption : true,
                ]
                try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: databaseURL, options: options)
            } catch {
                fatalError("There was an error adding persistent SQLite store on url \(databaseURL)")
            }
            
            self.storeCoordinator = coordinator
        } else {
            fatalError("CoreDataManager not set up. Use CoreDataManager.setupWithModel()")
        }
        
    }
    
    fileprivate func setupInMemoryStoreCoordinator() {
        if self.storeCoordinator != nil {
            return
        }
        
        let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        do {
            try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
            self.storeCoordinator = coordinator
        } catch {
            fatalError("There was an error adding in-memory store")
        }
    }
}

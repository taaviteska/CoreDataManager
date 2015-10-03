//
//  CoreDataManager.swift
//  Pods
//
//  Created by Taavi Teska on 05/09/15.
//
//

import CoreData


public class CoreDataManager:NSObject {
    
    public static let sharedInstance = CoreDataManager()
    
    private(set) public var modelName: String?
    private(set) public var databaseURL: NSURL?
    
    private var storeCoordinator: NSPersistentStoreCoordinator?
    
    override public init(){
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contextDidSaveContext:", name: NSManagedObjectContextDidSaveNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    // MARK: Lazy contexts
    
    public lazy var mainContext: NSManagedObjectContext = {
        self.getManagedObjectContextWithType(NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        }()
    
    public lazy var backgroundContext: NSManagedObjectContext = {
        self.getManagedObjectContextWithType(NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        }()
    
    
    // MARK: Other lazy variables
    
    private lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
        }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        if let modelName = self.modelName {
            if let modelURL = NSBundle.mainBundle().URLForResource(modelName, withExtension: "momd") {
                if let model = NSManagedObjectModel(contentsOfURL: modelURL) {
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
    
    public func setupWithModel(model: String) {
        self.setupWithModel(model, andFileName: model.stringByAppendingString(".sqlite"))
    }
    
    public func setupWithModel(model: String, andFileName fileName: String) {
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(fileName)
        self.setupWithModel(model, andFileURL: url)
    }
    
    public func setupWithModel(model: String, andFileURL url: NSURL) {
        self.modelName = model
        self.databaseURL = url
        
        self.setupPersistentStoreCoordinator()
    }
    
    public func setupInMemoryWithModel(model: String) {
        self.modelName = model
        
        self.setupInMemoryStoreCoordinator()
    }
    
}


// MARK: - Context saving notifications

extension CoreDataManager {
    
    // call back function by saveContext, support multi-thread
    func contextDidSaveContext(notification: NSNotification) {
        let sender = notification.object as! NSManagedObjectContext
        if sender === self.mainContext {
            self.backgroundContext.performBlock {
                self.backgroundContext.mergeChangesFromContextDidSaveNotification(notification)
            }
        } else if sender === self.backgroundContext {
            self.mainContext.performBlock {
                self.mainContext.mergeChangesFromContextDidSaveNotification(notification)
            }
        }
    }
}


// MARK: - Private

extension CoreDataManager {

    private func getManagedObjectContextWithType(type: NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
        if let coordinator = self.storeCoordinator {
            let managedObjectContext = NSManagedObjectContext(concurrencyType: type)
            managedObjectContext.persistentStoreCoordinator = coordinator
            return managedObjectContext
        } else {
            fatalError("Store coordinator not set up. Use one of the CoreDataManager.setup() methods")
        }
    }
    
    // The persistent store coordinator for the application. This implementation creates a coordinator, having added the store for the application to it.
    private func setupPersistentStoreCoordinator() {
        if self.storeCoordinator != nil {
            return
        }
        
        let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        if let databaseURL = self.databaseURL {
            
            do {
                try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: databaseURL, options: nil)
            } catch {
                fatalError("There was an error adding persistent SQLite store on url \(databaseURL)")
            }
            
            self.storeCoordinator = coordinator
        } else {
            fatalError("CoreDataManager not set up. Use CoreDataManager.setupWithModel()")
        }
        
    }
    
    private func setupInMemoryStoreCoordinator() {
        if self.storeCoordinator != nil {
            return
        }
        
        let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        do {
            try coordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
            self.storeCoordinator = coordinator
        } catch {
            fatalError("There was an error adding in-memory store")
        }
    }
}

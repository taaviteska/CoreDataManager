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
    
    var modelName: String?
    var databaseName: String?
    
    private let store = CoreDataStore()
    
    override init(){
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contextDidSaveContext:", name: NSManagedObjectContextDidSaveNotification, object: nil)
    }
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    // MARK: - Setup
    
    public static func setupWithModel(model: String) {
        self.sharedInstance.modelName = model
        self.sharedInstance.databaseName = model.stringByAppendingString(".sqlite")
    }
    
    public static func setupWithModel(model: String, andDatabase database: String) {
        self.sharedInstance.modelName = model
        self.sharedInstance.databaseName = database
    }


    // MARK: - Managed Object Contexts
    
    public lazy var mainContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
        let coordinator = self.store.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    public lazy var backgroundContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
        let coordinator = self.store.persistentStoreCoordinator
        var backgroundContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        backgroundContext.persistentStoreCoordinator = coordinator
        return backgroundContext
        }()
    
    
    // MARK: - Managed Object Contexts - saving
    
    public func saveContext(context: NSManagedObjectContext) -> NSError? {
        var error: NSError? = nil
        if context.hasChanges {
            context.save(&error)
        }
        
        return error
    }
    
    public func saveContext() -> NSError? {
        return self.saveContext( self.backgroundContext )
    }
    
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
        } else {
            self.backgroundContext.performBlock {
                self.backgroundContext.mergeChangesFromContextDidSaveNotification(notification)
            }
            self.mainContext.performBlock {
                self.mainContext.mergeChangesFromContextDidSaveNotification(notification)
            }
        }
    }
}

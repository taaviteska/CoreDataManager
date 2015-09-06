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
    var databaseURL: NSURL?
    
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
        self.setupWithModel(model, andFileName: model.stringByAppendingString(".sqlite"))
    }
    
    public static func setupWithModel(model: String, andFileName fileName: String) {
        let url = self.sharedInstance.applicationDocumentsDirectory.URLByAppendingPathComponent(fileName)
        self.setupWithModel(model, andFileURL: url)
    }
    
    public static func setupWithModel(model: String, andFileURL url: NSURL) {
        self.sharedInstance.modelName = model
        self.sharedInstance.databaseURL = url
        
        self.sharedInstance.store.setupPersistentStoreCoordinator()
    }
    
    public static func setupInMemoryWithModel(model: String) {
        self.sharedInstance.modelName = model
        
        self.sharedInstance.store.setupInMemoryStoreCoordinator()
    }


    // MARK: - Managed Object Contexts
    
    public lazy var mainContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
        if let coordinator = self.store.storeCoordinator {
            var managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = coordinator
            return managedObjectContext
        } else {
            fatalError("Store coordinator not set up. Use one of the CoreDataManager.setup() methods")
        }
    }()
    
    public lazy var backgroundContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
        if let coordinator = self.store.storeCoordinator {
            var backgroundContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
            backgroundContext.persistentStoreCoordinator = coordinator
            return backgroundContext
        } else {
            fatalError("Store coordinator not set up. Use one of the CoreDataManager.setup() methods")
        }
        }()
    
    
    // MARK: - Managed Object Contexts - saving
    
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
    
    
    //MARK: - Other
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
        }()
}

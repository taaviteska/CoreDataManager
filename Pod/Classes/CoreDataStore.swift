//
//  CoreDataStore.swift
//  SwiftCoreDataSimpleDemo
//
//  Created by CHENHAO on 14-7-9.
//  Copyright (c) 2014 CHENHAO. All rights reserved.
//

import CoreData

class CoreDataStore: NSObject{
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "me.iascchen.MyTTT" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        if let modelName = CoreDataManager.sharedInstance.modelName {
            if let modelURL = NSBundle.mainBundle().URLForResource(modelName, withExtension: "momd") {
                if let model = NSManagedObjectModel(contentsOfURL: modelURL) {
                    return model
                }
                
                fatalError("Couldn't find the managed object model with name \(modelName)\nChecked url: \(modelURL)")
            }
            
            fatalError("Couldn't find the managed object model with name \(modelName) in main bundle")
        }
        
        fatalError("CoreDataManager not set up. Use CoreDataManager.setupWithModel()")
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        if let databaseName = CoreDataManager.sharedInstance.databaseName {
            let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(databaseName)
            var error: NSError? = nil
            
            if coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) != nil {
                return coordinator
            }
            
            fatalError("There was an error adding persistent SQLite store on url \(url)")
        }
        
        fatalError("CoreDataManager not set up. Use CoreDataManager.setupWithModel()")
        }()
}

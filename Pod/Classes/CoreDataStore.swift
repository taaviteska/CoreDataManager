//
//  CoreDataStore.swift
//  SwiftCoreDataSimpleDemo
//
//  Created by CHENHAO on 14-7-9.
//  Copyright (c) 2014 CHENHAO. All rights reserved.
//

import CoreData

class CoreDataStore: NSObject {
    
    var storeCoordinator: NSPersistentStoreCoordinator?
    
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
        
        fatalError("CoreDataManager not set up. Use CoreDataManager.setupWithModel() or CoreDataManager.setupInMemoryWithModel()")
        }()
    
    // The persistent store coordinator for the application. This implementation creates a coordinator, having added the store for the application to it.
    func setupPersistentStoreCoordinator() {
        if self.storeCoordinator != nil {
            return
        }
        
        var coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        if let databaseURL = CoreDataManager.sharedInstance.databaseURL {
            var error: NSError? = nil
            
            if coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: databaseURL, options: nil, error: &error) == nil {
                fatalError("There was an error adding persistent SQLite store on url \(databaseURL)")
            }
            
            self.storeCoordinator = coordinator
        } else {
            fatalError("CoreDataManager not set up. Use CoreDataManager.setupWithModel()")
        }
        
    }
    
    func setupInMemoryStoreCoordinator() {
        if self.storeCoordinator != nil {
            return
        }
        
        var coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        var error: NSError?
        if coordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil, error: &error) != nil {
            self.storeCoordinator = coordinator
            
            return
        }
        
        fatalError("There was an error adding in-memory store")
    }
}

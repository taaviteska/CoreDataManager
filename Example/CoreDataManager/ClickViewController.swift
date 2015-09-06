//
//  ClickViewController.swift
//  CoreDataManager
//
//  Created by Taavi Teska on 09/05/2015.
//  Copyright (c) 2015 Taavi Teska. All rights reserved.
//

import UIKit
import CoreData

import CoreDataManager

class ClickViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    private let cdm = CoreDataManager.sharedInstance
    private var thisBatchID: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewClick:")
        self.navigationItem.rightBarButtonItem = addButton
        
        let lastBatchID = (self.cdm.mainContext.managerFor(Batch).max("id") as? Int) ?? 0
        self.thisBatchID = lastBatchID + 1
    }
    
    func insertNewClick(sender: AnyObject) {
        
        let context = self.cdm.backgroundContext
        context.performBlock {
            let clickManager = context.managerFor(Click)
            let lastClickID = (clickManager.max("clickID") as? Int) ?? 0
            
            let newClick = NSEntityDescription.insertNewObjectForEntityForName("Click", inManagedObjectContext: context) as! Click
            newClick.timeStamp = NSDate()
            newClick.clickID = lastClickID + 1
            
            if let batch = context.managerFor(Batch).filter(format: "id = %d", self.thisBatchID).first {
                newClick.batch = batch
            } else {
                let newBatch = NSEntityDescription.insertNewObjectForEntityForName("Batch", inManagedObjectContext: context) as! Batch
                
                newBatch.id = self.thisBatchID
                newBatch.name = "Batch \(self.thisBatchID)"
                newClick.batch = newBatch
            }
            context.save()
        }
    }
    
    // MARK: - Private
    
    private func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
        cell.textLabel!.text = object.valueForKey("timeStamp")!.description
    }
    
    // MARK: - Table View
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let firstClick = self.fetchedResultsController.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: section)) as! Click
        
        return firstClick.batch.name
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ClickCell", forIndexPath: indexPath) as! UITableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let click = self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
            let clickID = click.valueForKey("clickID") as! Int
            
            let context = self.cdm.backgroundContext
            context.performBlock {
                let fetchRequest = NSFetchRequest(entityName: "Click")
                fetchRequest.predicate = NSPredicate(format: "clickID = %d", clickID)
                fetchRequest.fetchLimit = 1
                var error:NSError?
                let clicks = context.executeFetchRequest(fetchRequest, error: &error) as! [NSManagedObject]
                for click in clicks {
                    click.delete()
                }
                context.save()
            }
        }
    }
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest(entityName: "Click")
        
        let sortDescriptor = NSSortDescriptor(key: "timeStamp", ascending: false)
        let sortDescriptors = [sortDescriptor]
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.cdm.mainContext, sectionNameKeyPath: "batch.name", cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        var error: NSError? = nil
        if !_fetchedResultsController!.performFetch(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController? = nil
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
}


//
//  ClickViewController.swift
//  CoreDataManager
//
//  Created by Taavi Teska on 09/05/2015.
//  Copyright (c) 2015 Taavi Teska. All rights reserved.
//

import CoreData
import CoreDataManager
import UIKit

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
            try! context.saveIfChanged()
        }
    }
    
    // MARK: - Private
    
    private func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        if let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Click {
            cell.textLabel!.text = object.timeStamp.description
        }
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
        let sectionInfo = self.fetchedResultsController.sections![section] 
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ClickCell", forIndexPath: indexPath)
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
                context.managerFor(Click).filter(format: "clickID = %d", clickID).delete()
                try! context.saveIfChanged()
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
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.cdm.mainContext, sectionNameKeyPath: "batch.name", cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        try! _fetchedResultsController!.performFetch()
        
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
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
}


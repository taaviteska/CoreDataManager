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
    
    fileprivate let cdm = CoreDataManager.sharedInstance
    fileprivate var thisBatchID: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ClickViewController.insertNewClick(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        
        let lastBatchID = (self.cdm.mainContext.managerFor(Batch).max("id") as? Int) ?? 0
        self.thisBatchID = lastBatchID + 1
    }
    
    func insertNewClick(_ sender: AnyObject) {
        
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
    
    fileprivate func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        if let object = self.fetchedResultsController.object(at: indexPath) as? Click {
            cell.textLabel!.text = object.timeStamp.description
        }
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let firstClick = self.fetchedResultsController.object(at: IndexPath(row: 0, section: section)) as! Click
        
        return firstClick.batch.name
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] 
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ClickCell", for: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let click = self.fetchedResultsController.object(at: indexPath) as! NSManagedObject
            let clickID = click.value(forKey: "clickID") as! Int
            
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
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            self.configureCell(tableView.cellForRow(at: indexPath!)!, atIndexPath: indexPath!)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
}


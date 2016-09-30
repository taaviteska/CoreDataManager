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
    private var thisBatchID: NSNumber!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ClickViewController.insertNewClick(sender:)))
        self.navigationItem.rightBarButtonItem = addButton
        
        let lastBatchID = (self.cdm.mainContext.managerFor(Batch.self).max("id") as? NSNumber) ?? 0
        self.thisBatchID = NSNumber(integerLiteral: lastBatchID.intValue + 1)
    }
    
    func insertNewClick(sender: AnyObject) {
        
        let context = self.cdm.backgroundContext
        context.perform {
            let clickManager = context.managerFor(Click.self)
            let lastClickID = (clickManager.max("clickID") as? Int) ?? 0
            
            let newClick = NSEntityDescription.insertNewObject(forEntityName: "Click", into: context) as! Click
            newClick.timeStamp = Date()
            newClick.clickID = NSNumber(integerLiteral: lastClickID + 1)
            
            if let batch = context.managerFor(Batch.self).filter(format: "id = %d", self.thisBatchID).first {
                newClick.batch = batch
            } else {
                let newBatch = NSEntityDescription.insertNewObject(forEntityName: "Batch", into: context) as! Batch
                
                newBatch.id = self.thisBatchID
                newBatch.name = "Batch \(self.thisBatchID.intValue)"
                newClick.batch = newBatch
            }
            try! context.saveIfChanged()
        }
    }
    
    // MARK: - Private
    
    private func configureCell(cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let object = self.fetchedResultsController.object(at: indexPath)
        cell.textLabel!.text = object.timeStamp.description
    }
    
    // MARK: - Table View
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let firstClick = self.fetchedResultsController.object(at: IndexPath(row: 0, section: section))
        
        return firstClick.batch.name
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] 
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ClickCell", for: indexPath)
        self.configureCell(cell: cell, atIndexPath: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let click = self.fetchedResultsController.object(at: indexPath)
            let clickID = click.clickID as Int
            
            let context = self.cdm.backgroundContext
            context.perform {
                _ = context.managerFor(Click.self).filter(format: "clickID = %d", clickID).delete()
                try! context.saveIfChanged()
            }
        }
    }
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController<Click> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest<Click>(entityName: "Click")
        
        let sortDescriptor = NSSortDescriptor(key: "timeStamp", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let aFetchedResultsController = NSFetchedResultsController<Click>(fetchRequest: fetchRequest, managedObjectContext: self.cdm.mainContext, sectionNameKeyPath: "batch.name", cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        try! _fetchedResultsController!.performFetch()
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController<Click>? = nil
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet([sectionIndex]), with: .fade)
        case .delete:
            self.tableView.deleteSections(IndexSet([sectionIndex]), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            self.tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            self.tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            self.configureCell(cell: self.tableView.cellForRow(at: indexPath!)!, atIndexPath: indexPath!)
        case .move:
            self.tableView.deleteRows(at: [indexPath!], with: .fade)
            self.tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
}


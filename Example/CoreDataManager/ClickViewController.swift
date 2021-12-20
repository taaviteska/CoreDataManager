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

class ClickViewController: UITableViewController {
    private let cdm = CoreDataManager.sharedInstance
    private lazy var thisBatchID: Int = {
        let lastBatchID = (cdm.mainContext.managerFor(Batch.self).max("id") as? Int) ?? 0
        return lastBatchID + 1
    }()
    
    // MARK: - Fetched results controller

    lazy var fetchedResultsController: NSFetchedResultsController<Click> = {
        let fetchRequest = NSFetchRequest<Click>(entityName: "Click")
        let sortDescriptor = NSSortDescriptor(key: "timeStamp", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let fetchedResultsController = NSFetchedResultsController<Click>(fetchRequest: fetchRequest, managedObjectContext: cdm.mainContext, sectionNameKeyPath: "batch.name", cacheName: nil)
        fetchedResultsController.delegate = self
        try? fetchedResultsController.performFetch()
        return fetchedResultsController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.leftBarButtonItem = editButtonItem
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ClickViewController.insertNewClick(sender:)))
        navigationItem.rightBarButtonItem = addButton
    }
    
    @objc func insertNewClick(sender: AnyObject) {
        let backgroundContext = cdm.backgroundContext
        backgroundContext.perform {
            let clickManager = backgroundContext.managerFor(Click.self)
            let lastClickID = (clickManager.max("clickID") as? Int) ?? 0
            
            let newClick = Click.insert(into: backgroundContext)
            newClick?.timeStamp = Date()
            newClick?.clickID = NSNumber(value: lastClickID + 1)
            
            if let batch = backgroundContext.managerFor(Batch.self).filter(format: "id = %d", self.thisBatchID).first {
                newClick?.batch = batch
            } else {
                let newBatch = Batch.insert(into: backgroundContext)
                newBatch?.id = NSNumber(value: self.thisBatchID)
                newBatch?.name = "Batch \(self.thisBatchID)"
                newClick?.batch = newBatch
            }
            try? backgroundContext.saveIfChanged()
        }
    }
    
    // MARK: - Private
    
    private func configureCell(cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let object = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = object.timeStamp?.description
    }
    
    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let firstClick = fetchedResultsController.object(at: IndexPath(row: 0, section: section))
        
        return firstClick.batch?.name
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ClickCell", for: indexPath)
        configureCell(cell: cell, atIndexPath: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let click = fetchedResultsController.object(at: indexPath)
            let clickID = click.clickID
            
            let context = cdm.backgroundContext
            context.perform {
                _ = context.managerFor(Click.self).filter(format: "clickID = %@", clickID as CVarArg).delete()
                try? context.saveIfChanged()
            }
        }
    }
}

extension ClickViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet([sectionIndex]), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet([sectionIndex]), with: .fade)
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
            configureCell(cell: tableView.cellForRow(at: indexPath!)!, atIndexPath: indexPath!)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        @unknown default:
            fatalError("Unknown value of NSFetchedResultsChangeType")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}

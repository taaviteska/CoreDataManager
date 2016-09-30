import XCTest
import CoreData
import CoreDataManager
import CoreDataManager_Example

class ManagedObjectManagerTestCase: XCTestCase {
    
    var cdm:CoreDataManager!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        self.cdm = CoreDataManager()
        self.cdm.setupInMemoryWithModel("CoreDataManager")
        
        self.cdm.mainContext.performAndWait { () -> Void in
            let batch = NSEntityDescription.insertNewObject(forEntityName: "Batch", into: self.cdm.mainContext) as! Batch
            batch.id = 100
            batch.name = "Batch 100"
            
            for i in 0...4 {
                let click = NSEntityDescription.insertNewObject(forEntityName: "Click", into: self.cdm.mainContext) as! Click
                click.clickID = NSNumber(integerLiteral: i)
                click.timeStamp = NSDate() as Date
                click.batch = batch
            }
            
            try! self.cdm.mainContext.saveIfChanged()
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreatingManager() {
        let manager = self.cdm.mainContext.managerFor(Click.self)
        XCTAssertEqual(manager.entityName(), "Click", "Managed object manager's entity is wrong")
    }
    
    func testAggregation() {
        var manager = self.cdm.mainContext.managerFor(Click.self)
        XCTAssertEqual(manager.count, 5, "Total clicks count is wrong")
        
        manager = self.cdm.mainContext.managerFor(Click.self)
        XCTAssertEqual(manager.filter(NSPredicate(format: "clickID < 0")).count, 0, "Total clicks count is wrong with filter")
        
        manager = self.cdm.mainContext.managerFor(Click.self)
        XCTAssertEqual(manager.filter(NSPredicate(format: "clickID < 2")).count, 2, "Clicks count is wrong")
        
        manager = self.cdm.mainContext.managerFor(Click.self)
        XCTAssertEqual(manager.filter(NSPredicate(format: "clickID < 10")).count, 5, "Total clicks count with filter wrong")
        
        // TODO: We use SQLite here because in-memory store has a bug
        // http://stackoverflow.com/questions/4387403/nscfnumber-count-unrecognized-selector
        let fileManager = FileManager.default
        let documentDirs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsURL = documentDirs[documentDirs.count-1] 
        let testingURL = documentsURL.appendingPathComponent("Testing")
        let databaseURL = testingURL.appendingPathComponent("TestDatabase.sqlite")
        let SQLiteCDM = CoreDataManager()
        
        try! fileManager.createDirectory(atPath: testingURL.path, withIntermediateDirectories: true, attributes: nil)
        SQLiteCDM.setupWithModel("CoreDataManager", andFileURL: databaseURL)
        
        let SQLiteManager = SQLiteCDM.mainContext.managerFor(Click.self)
        SQLiteCDM.mainContext.performAndWait { () -> Void in
            let batch = NSEntityDescription.insertNewObject(forEntityName: "Batch", into: SQLiteCDM.mainContext) as! Batch
            batch.id = 100
            batch.name = "Batch 100"
            
            for i in 0...4 {
                let click = NSEntityDescription.insertNewObject(forEntityName: "Click", into: SQLiteCDM.mainContext) as! Click
                click.clickID = NSNumber(integerLiteral: i)
                click.timeStamp = Date()
                click.batch = batch
            }
            
            try! SQLiteCDM.mainContext.saveIfChanged()
            
            XCTAssertEqual(SQLiteManager.min("clickID") as? Int, 0, "Aggregation MIN is wrong")
            
            XCTAssertEqual(SQLiteManager.max("clickID") as? Int, 4, "Aggregation MAX is wrong")
            
            XCTAssertEqual(SQLiteManager.sum("clickID") as? Int, 10, "Aggregation SUM is wrong")
            
            XCTAssertEqual(SQLiteManager.aggregate("average", forKeyPath: "clickID") as? Int, 2, "Aggregation AVG is wrong")
        }
        
        
        // Clear documents directory
        let fileNames = try! fileManager.contentsOfDirectory(atPath: documentsURL.path)
        
        // For each file in the directory, create full path and delete the file
        for fileName in fileNames {
            if fileName.hasPrefix("Test") {
                try! fileManager.removeItem(at: documentsURL.appendingPathComponent(fileName))
            }
        }
    }
    
    func testFiltering() {
        var manager = self.cdm.mainContext.managerFor(Click.self)
        XCTAssertEqual(manager.array.count, 5, "Total clicks count from array is wrong with filter")
        
        manager = self.cdm.mainContext.managerFor(Click.self)
        XCTAssertEqual(manager.filter(NSPredicate(format: "clickID < 0")).array.count, 0, "Total clicks count from array is wrong")
        
        manager = self.cdm.mainContext.managerFor(Click.self)
        XCTAssertEqual(manager.filter(NSPredicate(format: "clickID < 2")).array.count, 2, "Clicks count from array is wrong")
        
        manager = self.cdm.mainContext.managerFor(Click.self)
        XCTAssertEqual(manager.filter(NSPredicate(format: "clickID < 10")).array.count, 5, "Total clicks from array count with filter wrong")
    }
    
    func testOrdering() {
        var manager = self.cdm.mainContext.managerFor(Click.self)
        var clicks = manager.orderBy("clickID").array
        
        for i in 0...4 {
            XCTAssertEqual(clicks[i].clickID.intValue, i, "Ascending ordering fails")
        }
        
        manager = self.cdm.mainContext.managerFor(Click.self)
        clicks = manager.orderBy("-clickID").array
        
        for i in 0...4 {
            XCTAssertEqual(clicks[i].clickID.intValue, 4-i, "Descending ordering fails")
        }
    }
    
    func testFetching() {
        var manager = self.cdm.mainContext.managerFor(Click.self)
        if let click = manager.orderBy("clickID").first {
            XCTAssertEqual(click.clickID, 0, "Fetching first click fails")
        } else {
            XCTFail("First click not found")
        }
        
        manager = self.cdm.mainContext.managerFor(Click.self)
        if let click = manager.orderBy("clickID").last {
            XCTAssertEqual(click.clickID, 4, "Fetching last click fails")
        } else {
            XCTFail("Last click not found")
        }
    }
    
    func testDeleting() {
        var manager = self.cdm.mainContext.managerFor(Click.self)
        self.cdm.mainContext.performAndWait { () -> Void in
            _ = manager.filter(format: "clickID > 0").delete()
            try! self.cdm.mainContext.saveIfChanged()
            
            manager = self.cdm.mainContext.managerFor(Click.self)
            XCTAssertEqual(manager.count, 1, "Clicks count after saving is not correct")
        }
    }
}

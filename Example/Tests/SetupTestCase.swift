import XCTest
import CoreDataManager

class SetupTestCase: XCTestCase {
    
    let fileManager = FileManager.default
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        try! self.fileManager.createDirectory(atPath: self.documentsURLForTesting(forTesting: true).path, withIntermediateDirectories: true, attributes: nil)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        // Clear documents directory
        let documentsURL = self.documentsURLForTesting(forTesting: false)
        let fileNames = try! self.fileManager.contentsOfDirectory(atPath: documentsURL.path)
        
        // For each file in the directory, create full path and delete the file
        for fileName in fileNames {
            if fileName.hasPrefix("Test") {
                try! fileManager.removeItem(at: documentsURL.appendingPathComponent(fileName))
            }
        }
    }
    
    func documentsURLForTesting(forTesting: Bool) -> URL {
        let documentDirs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsURL = documentDirs[documentDirs.count-1] 
        
        if forTesting {
            return documentsURL.appendingPathComponent("Testing")
        }
        
        return documentsURL
    }
    
    func testInMemoryStorage() {
        let cdm = CoreDataManager()
        cdm.setupInMemoryWithModel("CoreDataManager")
        
        if let modelName = cdm.modelName {
            XCTAssertEqual(modelName, "CoreDataManager", "CoreDataManager model name is incorrect")
        } else {
            XCTFail("CoreDataManager model name is not set")
        }
        
        XCTAssertNil(cdm.databaseURL, "CoreDataManager database URL should not be set")
        
    }
    
    func testStorageWithModel() {
        let cdm = CoreDataManager()
        cdm.setupWithModel("CoreDataManager")
        
        if let modelName = cdm.modelName {
            XCTAssertEqual(modelName, "CoreDataManager", "CoreDataManager model name is incorrect")
        } else {
            XCTFail("CoreDataManager model name is not set")
        }
        
        if let databaseURL = cdm.databaseURL {
            let testdatabaseURLString = self.documentsURLForTesting(forTesting: false).appendingPathComponent("CoreDataManager.sqlite").absoluteString
            let databaseURLString = databaseURL.absoluteString
            
            XCTAssertEqual(databaseURLString, testdatabaseURLString, "CoreDataManager database not created in the correct place")
            
            self.fileManager.fileExists(atPath: databaseURL.path)
        } else {
            XCTFail("CoreDataManager database URL is not set")
        }
    }
    
    func testStorageWithModelAndFileName() {
        let cdm = CoreDataManager()
        cdm.setupWithModel("CoreDataManager", andFileName: "TestDatabase.sqlite")
        
        if let modelName = cdm.modelName {
            XCTAssertEqual(modelName, "CoreDataManager", "CoreDataManager model name is incorrect")
        } else {
            XCTFail("CoreDataManager model name is not set")
        }
        
        if let databaseURL = cdm.databaseURL {
            let testdatabaseURLString = self.documentsURLForTesting(forTesting: false).appendingPathComponent("TestDatabase.sqlite").absoluteString
            let databaseURLString = databaseURL.absoluteString
            
            XCTAssertEqual(databaseURLString, testdatabaseURLString, "CoreDataManager database not created in the correct place")
            
            self.fileManager.fileExists(atPath: databaseURL.path)
        } else {
            XCTFail("CoreDataManager database URL is not set")
        }
    }
    
    func testStorageWithModelAndFileURL() {
        let cdm = CoreDataManager()
        let testDatabaseURL = self.documentsURLForTesting(forTesting: true).appendingPathComponent("TestDatabase.sqlite")
        
        cdm.setupWithModel("CoreDataManager", andDatabaseURL: testDatabaseURL)
        
        if let modelName = cdm.modelName {
            XCTAssertEqual(modelName, "CoreDataManager", "CoreDataManager model name is incorrect")
        } else {
            XCTFail("CoreDataManager model name is not set")
        }
        
        if let databaseURL = cdm.databaseURL {
            let databaseURLString = databaseURL.absoluteString
            
            XCTAssertEqual(databaseURLString, testDatabaseURL.absoluteString, "CoreDataManager database not created in the correct place")
            
            self.fileManager.fileExists(atPath: testDatabaseURL.path)
        } else {
            XCTFail("CoreDataManager database URL is not set")
        }
    }
    
}

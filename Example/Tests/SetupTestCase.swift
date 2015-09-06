import XCTest
import CoreDataManager

class SetupTestCase: XCTestCase {
    
    let fileManager = NSFileManager.defaultManager()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        self.fileManager.createDirectoryAtPath(self.documentsURLForTesting(true).path!, withIntermediateDirectories: true, attributes: nil, error: nil)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        // Clear documents directory
        let documentsPath = self.documentsURLForTesting(false).path!
        if let fileNames = self.fileManager.contentsOfDirectoryAtPath(documentsPath, error: nil) as? [String] {
            // For each file in the directory, create full path and delete the file
            for fileName in fileNames {
                if fileName.hasPrefix("Test") {
                    fileManager.removeItemAtPath(documentsPath.stringByAppendingPathComponent(fileName), error: nil)
                }
            }
        }
    }
    
    func documentsURLForTesting(forTesting: Bool) -> NSURL {
        let documentDirs = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentsURL = documentDirs[documentDirs.count-1] as! NSURL
        
        if forTesting {
            return documentsURL.URLByAppendingPathComponent("Testing")
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
            let testdatabaseURLString = self.documentsURLForTesting(false).URLByAppendingPathComponent("CoreDataManager.sqlite").absoluteString!
            
            if let databaseURLString = databaseURL.absoluteString {
                XCTAssertEqual(databaseURLString, testdatabaseURLString, "CoreDataManager database not created in the correct place")
            } else {
                XCTFail("CoreDataManager database URL's absolute string is nil")
            }
            
            self.fileManager.fileExistsAtPath(databaseURL.path!)
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
            let testdatabaseURLString = self.documentsURLForTesting(false).URLByAppendingPathComponent("TestDatabase.sqlite").absoluteString!
            
            if let databaseURLString = databaseURL.absoluteString {
                XCTAssertEqual(databaseURLString, testdatabaseURLString, "CoreDataManager database not created in the correct place")
            } else {
                XCTFail("CoreDataManager database URL's absolute string is nil")
            }
            
            self.fileManager.fileExistsAtPath(databaseURL.path!)
        } else {
            XCTFail("CoreDataManager database URL is not set")
        }
    }
    
    func testStorageWithModelAndFileURL() {
        let cdm = CoreDataManager()
        let testDatabaseURL = self.documentsURLForTesting(true).URLByAppendingPathComponent("TestDatabase.sqlite")
        
        cdm.setupWithModel("CoreDataManager", andFileURL: testDatabaseURL)
        
        if let modelName = cdm.modelName {
            XCTAssertEqual(modelName, "CoreDataManager", "CoreDataManager model name is incorrect")
        } else {
            XCTFail("CoreDataManager model name is not set")
        }
        
        if let databaseURL = cdm.databaseURL {
            if let databaseURLString = databaseURL.absoluteString {
                XCTAssertEqual(databaseURLString, testDatabaseURL.absoluteString!, "CoreDataManager database not created in the correct place")
            } else {
                XCTFail("CoreDataManager database URL's absolute string is nil")
            }
            
            self.fileManager.fileExistsAtPath(testDatabaseURL.path!)
        } else {
            XCTFail("CoreDataManager database URL is not set")
        }
    }
    
}
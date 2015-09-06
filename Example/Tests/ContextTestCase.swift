import XCTest
import CoreData
import CoreDataManager

class ContextTestCase: XCTestCase {
    
    var cdm:CoreDataManager!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        self.cdm = CoreDataManager()
        self.cdm.setupInMemoryWithModel("CoreDataManager")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMainContext() {
        let context = self.cdm.mainContext
        
        XCTAssertEqual(context.concurrencyType, .MainQueueConcurrencyType, "Main contexts is not main queue concurrency type")
    }
    
    func testBackgroundContext() {
        let context = self.cdm.backgroundContext
        
        XCTAssertEqual(context.concurrencyType, .PrivateQueueConcurrencyType, "Background contexts is not private queue concurrency type")
    }
}

//
//  SerializerTestCase.swift
//  CoreDataManager
//
//  Created by Taavi Teska on 13/09/15.
//  Copyright (c) 2015 CocoaPods. All rights reserved.
//

import CoreDataManager
import CoreDataManager_Example
import SwiftyJSON
import XCTest

class SerializerTestCase: XCTestCase {
    
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
    
    func testDataSync() {
        
        let serializer = CDMSerializer<Batch>()
        serializer.identifiers = ["id"]
        serializer.mapping = [
            "id": CDMAttributeNumber(["id"]),
            "name": CDMAttributeString(["batch", "name"]),
        ]
        
        let jsonData = JSON([
            [
                "id": 1,
                "batch": [
                    "name": "Batch 1"
                ]
            ],[
                "id": 4,
                "batch": [
                    "name": "Batch 4"
                ],
            ]
            ])
        
        let expectation = self.expectationWithDescription("Syncing data didn't complete")
        
        self.cdm.backgroundContext.syncData(jsonData, withSerializer: serializer) { (error) -> Void in
            XCTAssertNil(error)
            
            let batches = self.cdm.mainContext.managerFor(Batch).orderBy("-id").array
            XCTAssertEqual(batches.count, 2, "Batches count after sync doesn't match")
            
            XCTAssertEqual(batches[0].id, 4, "Second batch's ID doesn't match")
            XCTAssertEqual(batches[0].name, "Batch 4", "Second batch's name doesn't match")
            
            XCTAssertEqual(batches[1].id, 1, "First batch's ID doesn't match")
            XCTAssertEqual(batches[1].name, "Batch 1", "First batch's name doesn't match")
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: { (error) -> Void in
            print(error)
        })
    }
    
    func testNestedDataSync() {
        
        let serializer = CDMSerializer<Batch>()
        serializer.identifiers = ["id"]
        serializer.mapping = [
            "id": CDMAttributeNumber(["id"]),
            "name": CDMAttributeString(["batch", "name"]),
            "clicks": CDMAttributeToMany(["clicked"], serializerCallback: {_ in 
                return ClickSerializer()
            }),
        ]
        
        let jsonData = JSON([
            [
                "id": 1,
                "batch": [
                    "name": "Batch 1"
                ],
                "clicked": [
                    ["id": 2, "time": "2014-07-06T07:59:00Z"],
                    ["id": 3, "time": "2014-07-06T07:59:00Z"],
                ]
            ],[
                "id": 4,
                "batch": [
                    "name": "Batch 4"
                ],
            ]
            ])
        
        let expectation = self.expectationWithDescription("Syncing data didn't complete")
        
        self.cdm.backgroundContext.syncData(jsonData, withSerializer: serializer) { (error) -> Void in
            XCTAssertNil(error)
            
            let clicks = self.cdm.mainContext.managerFor(Click).filter(format: "batch.id = %d", 1).orderBy("clickID").array
            
            XCTAssertEqual(clicks.count, 2, "Clicks count after sync doesn't match")
            
            XCTAssertEqual(clicks[0].clickID, 2, "Second click's ID doesn't match")
            
            XCTAssertEqual(clicks[1].clickID, 3, "First click's ID doesn't match")
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: { (error) -> Void in
            print(error)
        })
    }
    
    func testInsert() {
        
        let expectation = self.expectationWithDescription("Inserting batch didn't complete")
        
        XCTAssertEqual(self.cdm.mainContext.managerFor(Batch).count, 0, "Batches count before insert doesn't match")
        
        let json = JSON(["id": 10, "name": "Batch 10"])
        
        self.cdm.backgroundContext.insert(Batch.self, withJSON: json) { (error) -> Void in
            XCTAssertNil(error)
            XCTAssertEqual(self.cdm.mainContext.managerFor(Batch).count, 1, "Batches count after first insert doesn't match")
            
            self.cdm.backgroundContext.insert(Batch.self, withJSON: json, complete: { (error) -> Void in
                XCTAssertNil(error)
                XCTAssertEqual(self.cdm.mainContext.managerFor(Batch).count, 2, "Batches count after second insert doesn't match")
                
                expectation.fulfill()
            })
        }
        
        self.waitForExpectationsWithTimeout(1, handler: { (error) -> Void in
            print(error)
        })
    }
    
    func testInsertOrUpdate() {
        
        let expectation = self.expectationWithDescription("InsertOrUpdating batch didn't complete")
        
        XCTAssertEqual(self.cdm.mainContext.managerFor(Batch).count, 0, "Batches count before insertOrUpdate doesn't match")
        
        let json = JSON(["id": 15, "name": "Batch 15"])
        
        self.cdm.backgroundContext.insertOrUpdate(Batch.self, withJSON: json, andIdentifiers: ["id"]) { (error) -> Void in
            XCTAssertNil(error)
            XCTAssertEqual(self.cdm.mainContext.managerFor(Batch).count, 1, "Batches count after first insert or update doesn't match")
            
            self.cdm.backgroundContext.insertOrUpdate(Batch.self, withJSON: json, andIdentifiers: ["id"]) { (error) -> Void in
                XCTAssertNil(error)
                XCTAssertEqual(self.cdm.mainContext.managerFor(Batch).count, 1, "Batches count after second insert or update doesn't match")
                
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(1, handler: { (error) -> Void in
            print(error)
        })
    }

}

class ClickSerializer<T:Click>: CDMSerializer<T> {
    
    override init() {
        super.init()
        
        self.identifiers = ["clickID"]
        self.mapping = [
            "clickID": CDMAttributeNumber(["id"]),
            "timeStamp": CDMAttributeISODate(["time"]),
        ]
    }
}

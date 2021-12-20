//
//  SerializerTestCase.swift
//  CoreDataManager
//
//  Created by Taavi Teska on 13/09/15.
//  Copyright (c) 2015 CocoaPods. All rights reserved.
//

import CoreData
import CoreDataManager
import CoreDataManager_Example
import SwiftyJSON
import XCTest

class SerializerTestCase: XCTestCase {
    var cdm: CoreDataManager!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        cdm = CoreDataManager()
        //cdm.setupInMemoryWithModel("CoreDataManager")
        cdm.setupWithModel("CoreDataManager", andDatabaseURL: databaseURL)
    }
    
    override func tearDown() {
        cdm.mainContext.performAndWait {
            cdm.mainContext.managerFor(Batch.self).delete()
            try? cdm.mainContext.saveIfChanged()
        }
        super.tearDown()
    }
    
    private lazy var databaseURL: URL = {
        let fileManager = FileManager.default
        let documentDirs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsURL = documentDirs[documentDirs.count - 1]
        let testingURL = documentsURL.appendingPathComponent("Testing")
        let databaseURL = testingURL.appendingPathComponent("TestDatabase.sqlite")
        try? fileManager.createDirectory(atPath: testingURL.path, withIntermediateDirectories: true, attributes: nil)
        return databaseURL
    }()
    
    func testDataSync() {
        let serializer = CDMSerializer<Batch>()
        serializer.identifiers = ["id"]
        serializer.mapping = [
            "id": CDMAttributeNumber(["id"]),
            "name": CDMAttributeString(["batch", "name"])
        ]
        
        let jsonData = JSON([
            [
                "id": 1,
                "batch": [
                    "name": "Batch 1"
                ]
            ], [
                "id": 4,
                "batch": [
                    "name": "Batch 4"
                ]
            ]
        ])
        
        let expectation = expectation(description: "Syncing data didn't complete")
        
        cdm.backgroundContext.syncData(jsonData, withSerializer: serializer) { (error) -> Void in
            XCTAssertNil(error)
            
            let batches = self.cdm.mainContext.managerFor(Batch.self).orderBy("-id").array
            XCTAssertEqual(batches.count, 2, "Batches count after sync doesn't match")
            
            XCTAssertEqual(batches[0].id, 4, "Second batch's ID doesn't match")
            XCTAssertEqual(batches[0].name, "Batch 4", "Second batch's name doesn't match")
            
            XCTAssertEqual(batches[1].id, 1, "First batch's ID doesn't match")
            XCTAssertEqual(batches[1].name, "Batch 1", "First batch's name doesn't match")
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func testNestedDataArraySync() {
        let serializer = CDMSerializer<Batch>()
        serializer.identifiers = ["id"]
        serializer.mapping = [
            "id": CDMAttributeNumber(["id"]),
            "name": CDMAttributeString(["batch", "name"]),
            "clicks": CDMAttributeToMany(["clicked"], serializerCallback: { _ in
                ClickSerializer(inverseRelationship: InverseRelationship(keyPath: "batch", parentSerializer: serializer))
            })
        ]
        
        let jsonData = JSON(
            [
                [
                    "id": 1,
                    "batch": [
                        "name": "Batch 1"
                    ],
                    "clicked": [
                        ["id": 1,
                         "time": "2014-07-06T07:59:00Z",
                         "point": [
                            "id": 1,
                            "x": 1,
                            "y": 1]
                        ],
                        ["id": 2,
                         "time": "2014-07-06T07:59:00Z",
                         "point": [
                            "id": 2,
                            "x": 2,
                            "y": 2]
                        ]
                    ]
                ],
                [
                    "id": 4,
                    "batch": [
                        "name": "Batch 4"
                    ],
                    "clicked": [
                        ["id": 1,
                         "time": "2014-07-06T07:59:00Z",
                         "point": [
                            "id": 1,
                            "x": 1,
                            "y": 1]
                        ]
                    ]
                ]
            ]
        )
        
        let expectation = expectation(description: "Syncing data didn't complete")
        
        cdm.backgroundContext.syncData(jsonData, withSerializer: serializer) { (error) -> Void in
            XCTAssertNil(error)
            let allBatchs = self.cdm.mainContext.managerFor(Batch.self).orderBy("id").array
            let allClicks = self.cdm.mainContext.managerFor(Click.self).orderBy("clickID").array
            let allPoints = self.cdm.mainContext.managerFor(Point.self).orderBy("id").array
            
            XCTAssertEqual(allBatchs.count, 2, "Batchs count after sync doesn't match")
            XCTAssertEqual(allClicks.count, 3, "Clicks count after sync doesn't match")
            XCTAssertEqual(allPoints.count, 3, "Points count after sync doesn't match")
            
            let batch1Clicks = self.cdm.mainContext.managerFor(Click.self).filter(format: "batch.id = %d", 1).orderBy("clickID").array
            XCTAssertEqual(batch1Clicks.count, 2, "Clicks count after sync doesn't match")
            
            let click1 = batch1Clicks.first
            let click2 = batch1Clicks.last
            
            XCTAssertEqual(click1?.batch?.id, 1, "First click's batchID doesn't match")
            XCTAssertEqual(click1?.clickID, 1, "First click's ID doesn't match")
            XCTAssertEqual(click1?.point?.id, 1, "First point's ID doesn't match")
            
            XCTAssertEqual(click2?.batch?.id, 1, "Second click's batchID doesn't match")
            XCTAssertEqual(click2?.clickID, 2, "Second click's ID doesn't match")
            XCTAssertEqual(click2?.point?.id, 2, "Second point's ID doesn't match")
            
            let batch4Clicks = self.cdm.mainContext.managerFor(Click.self).filter(format: "batch.id = %d", 4).orderBy("clickID").array
            XCTAssertEqual(batch4Clicks.count, 1, "Clicks count after sync doesn't match")
            
            let click4 = batch4Clicks.first

            XCTAssertEqual(click4?.batch?.id, 4, "First click's batchID doesn't match")
            XCTAssertEqual(click4?.clickID, 1, "First click's ID doesn't match")
            XCTAssertEqual(click4?.point?.id, 1, "Second point's ID doesn't match")

            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1000)
    }
    
    func testNestedDataSync() {
        let serializer = CDMSerializer<Batch>()
        serializer.identifiers = ["id"]
        serializer.mapping = [
            "id": CDMAttributeNumber(["id"]),
            "name": CDMAttributeString(["batch", "name"]),
            "clicks": CDMAttributeToMany(["clicked"], serializerCallback: { _ in
                ClickSerializer(inverseRelationship: InverseRelationship(keyPath: "batch", parentSerializer: serializer))
            })
        ]
        
        let jsonData = JSON(
            [
                "id": 1,
                "batch": [
                    "name": "Batch 1"
                ],
                "clicked": [
                    ["id": 1,
                     "time": "2014-07-06T07:59:00Z",
                     "point": [
                        "id": 1,
                        "x": 1,
                        "y": 1]
                    ],
                    ["id": 2,
                     "time": "2014-07-06T07:59:00Z",
                     "point": [
                        "id": 2,
                        "x": 2,
                        "y": 2]
                    ]
                ]
            ]
        )
        
        let expectation = expectation(description: "Syncing data didn't complete")
        
        cdm.backgroundContext.syncData(jsonData, withSerializer: serializer) { (error) -> Void in
            XCTAssertNil(error)
            let allClicks = self.cdm.mainContext.managerFor(Click.self).orderBy("clickID").array
            
            let allPoints = self.cdm.mainContext.managerFor(Point.self).orderBy("id").array
            
            XCTAssertEqual(allClicks.count, 2, "Clicks count after sync doesn't match")
            
            XCTAssertEqual(allPoints.count, 2, "Points count after sync doesn't match")
            
            let cilck2Points = self.cdm.mainContext.managerFor(Point.self).filter(format: "click.clickID = %d", 2).orderBy("id").array
            
            XCTAssertEqual(cilck2Points.count, 1, "Points count after sync doesn't match")
            
            XCTAssertEqual(cilck2Points.first?.id, 2, "First point's ID doesn't match")
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func testInsert() {
        let expectation = expectation(description: "Inserting batch didn't complete")
        
        XCTAssertEqual(cdm.mainContext.managerFor(Batch.self).count, 0, "Batches count before insert doesn't match")
        
        let json = JSON(["id": 10, "name": "Batch 10"])
        
        cdm.backgroundContext.insert(Batch.self, withJSON: json) { (error) -> Void in
            XCTAssertNil(error)
            XCTAssertEqual(self.cdm.mainContext.managerFor(Batch.self).count, 1, "Batches count after first insert doesn't match")
            
            self.cdm.backgroundContext.insert(Batch.self, withJSON: json, complete: { (error) -> Void in
                XCTAssertNil(error)
                XCTAssertEqual(self.cdm.mainContext.managerFor(Batch.self).count, 2, "Batches count after second insert doesn't match")
                
                expectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func testInsertOrUpdate() {
        let expectation = expectation(description: "InsertOrUpdating batch didn't complete")
        
        XCTAssertEqual(cdm.mainContext.managerFor(Batch.self).count, 0, "Batches count before insertOrUpdate doesn't match")
        
        let json = JSON(["id": 15, "name": "Batch 15"])
        
        cdm.backgroundContext.insertOrUpdate(Batch.self, withJSON: json, andIdentifiers: ["id"]) { (error) -> Void in
            XCTAssertNil(error)
            XCTAssertEqual(self.cdm.mainContext.managerFor(Batch.self).count, 1, "Batches count after first insert or update doesn't match")
            
            self.cdm.backgroundContext.insertOrUpdate(Batch.self, withJSON: json, andIdentifiers: ["id"]) { (error) -> Void in
                XCTAssertNil(error)
                XCTAssertEqual(self.cdm.mainContext.managerFor(Batch.self).count, 1, "Batches count after second insert or update doesn't match")
                
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10)
    }
}

class ClickSerializer<T: Click>: CDMSerializer<T> {
    override init(inverseRelationship: InverseRelationship?) {
        super.init(inverseRelationship: inverseRelationship)
        self.identifiers = ["clickID"]
        self.mapping = [
            "clickID": CDMAttributeNumber(["id"]),
            "timeStamp": CDMAttributeISODate(["time"]),
            "point": CDMAttributeToOne(["point"], serializerCallback: { _ in
                PointSerializer(inverseRelationship: InverseRelationship(keyPath: "click", parentSerializer: self))
            })
        ]
    }
}

class PointSerializer<T: Point>: CDMSerializer<T> {
    override init(inverseRelationship: InverseRelationship?) {
        super.init(inverseRelationship: inverseRelationship)
        self.identifiers = ["id"]
        self.mapping = [
            "id": CDMAttributeNumber(["id"]),
            "x": CDMAttributeNumber(["x"]),
            "y": CDMAttributeNumber(["y"])
        ]
    }
}

# CoreDataManager

[![Version](https://img.shields.io/cocoapods/v/CoreDataManager.svg?style=flat)](http://cocoapods.org/pods/CoreDataManager)
[![License](https://img.shields.io/cocoapods/l/CoreDataManager.svg?style=flat)](http://cocoapods.org/pods/CoreDataManager)
[![Platform](https://img.shields.io/cocoapods/p/CoreDataManager.svg?style=flat)](http://cocoapods.org/pods/CoreDataManager)
[![Twitter](https://img.shields.io/badge/twitter-@TaaviTeska-blue.svg?style=flat)](https://twitter.com/TaaviTeska)

CoreDataManager is a layer for simpler Core Data setup and JSON data synchronization

1. [Usage](#usage)
1. [Minimum requirements](#minimum-requirements)
1. [Installation](#installation)
1. [Setup](#setup)
1. [Managed object contexts](#managed-object-contexts)
    - [Fetching](#fetching-managed-objects)
    - [Filtering](#filtering-managed-objects)
    - [Ordering](#ordering-managed-objects)
    - [Aggregating](#aggregating-managed-objects)
    - [Deleting](#deleting-managed-objects)
1. [Serializers](#serializers)
    - [Variables](#serializer-variables)
    - [Methods](#serializer-methods)
    - [Mapping attributes](#serializer-mapping-attributes)
    - [Examples](#serializer-examples)
1. [Syncing JSON data](#syncing-json-data)
1. [Author](#author)
1. [Dependencies](#dependencies)
1. [Credits](#credits)
1. [License](#license)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Minimum requirements

- iOS 9.0
- Xcode 8

## Installation

CoreDataManager is available through [CocoaPods](http://cocoapods.org). Install it with the following command:

```bash
$ gem install cocoapods
```

To install CoreDataManager add a file named `Podfile` to the project's root folder with contents similar to:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

pod 'CoreDataManager', '~> 0.8.1'
```

Then, run the following command:

```bash
$ pod install
```

## Setup

Setup persistent store in your AppDelegate

```swift
import CoreDataManager
```

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.

    CoreDataManager.sharedInstance.setupWithModel("CoreDataManager")

    return true
}
```

Possible ways to set up CoreDataManager:

```swift
// Just replace your data model name
CoreDataManager.sharedInstance.setupWithModel("CoreDataManager")

// Replace your data model name and specify database file name.
CoreDataManager.sharedInstance.setupWithModel("CoreDataManager", andFileName: "CoreDataManager.sqlite")

// Replace your data model name and specify full URL to database file when the database shouldn't be in the user's documents directory.
let databaseURL = ...
CoreDataManager.sharedInstance.setupWithModel("CoreDataManager", andFileURL: databaseURL)

// Use in memory store for testing
CoreDataManager.sharedInstance.setupInMemoryWithModel("CoreDataManager")
```

## Managed object contexts

```swift
let cdm = CoreDataManager.sharedInstance

// Main context for UIKit
let mainCtx = cdm.mainContext

// Background context for making updates
let backgroundCtx = cdm.backgroundContext
```

### Fetching managed objects

```swift
// Array of employees
let employees = mainCtx.managerFor(Employee.self).array

// Count of employees
let employeeCount = mainCtx.managerFor(Employee.self).count

// First / last employee
let oldestEmployee = mainCtx.managerFor(Employee.self).orderBy("age").first
let youngestEmployee = mainCtx.managerFor(Employee.self).orderBy("age").last
```

### Filtering managed objects

Filter method accepts predicates and can be called with same arguments that a NSPredicate can be initialized

```swift
let youngEmployeeManager = mainCtx.managerFor(Employee.self).filter("age < 40")

// Young employees
let youngEmployees = youngEmployeeManager.array

// Count of young employees
let youngEmployeeCount = youngEmployeeManager.count
```

### Ordering managed objects

Applying minus sign (-) in front of the attribute will make the ordering descening

```swift
// Ascending array of employees ordered by age
let employeesFromYoungest = mainCtx.managerFor(Employee.self).orderBy(["age", "name"]).array

// Descending array of employees ordered by age
let employeesFromOldest = mainCtx.managerFor(Employee.self).orderBy(["-age", "name"]).array
```

### Aggregating managed objects

```swift
// Age of the youngest employee
let ageOfYoungestEmployee = mainCtx.managerFor(Employee.self).min("age")

// Age of the oldest employee
let ageOfOldestEmployee = mainCtx.managerFor(Employee.self).max("age")

// Total age of the employees
let totalAgeOfEmployees = mainCtx.managerFor(Employee.self).sum("age")

// Average age of the employees
let avgAgeOfEmployees = mainCtx.managerFor(Employee.self).aggregate("average", forKeyPath: "age")
```

### Deleting managed objects

```swift
// Delete employees older than 100
backgroundCtx.performBlock { () -> Void in
    backgroundCtx.managerFor(Employee.self).filter("age > 100").delete()
    backgroundCtx.save()
}
```

## Serializers

### Serializer variables

`identifiers` [String] - Attributes from the mapping that identify the specific object instance that is updated when syncing the data. If no instance is found in the local database then a new instance is created and saved to the database. *Defaults to empty list*.

`forceInsert` Bool - If set to true then the local database is not checked for matching instances and all the synced data is inserted. *Defaults to false*.

`insertMissing` Bool - Determines whether the instances that are not found in the local database should be inserted or not. This is ignored if forceInsert is set to true. *Defaults to true*.

`updateExisting`: Bool - Determines whether the instances that are found in the local database should be updated or not. This is ignored if forceInsert is set to true. *Defaults to true*.

`deleteMissing` Bool - Determines whether the instances that are not found in the synced data, but are present in the local database should be deleted or not. *Defaults to true*.

`mapping` [String: CDMAttribute] - Defines tha mapping for creating the managed object instances. *Defaults to empty dictionary*

### Serializer methods

`func getValidators() -> [CDMValidator]` - Defines the validators for the serializer. Each validator is run before any syncing begins. Each validator gets every item from the synced data one by one as *JSON* and returns the modified value as *JSON*. Validators can also return *nil* if the validation does not pass - this is not taken into account in the following sync.

`func getGroupers() -> [NSPredicate]` - Groupers are a list of predicates that define a subgroup of the managed objects stored in the database that the sync is run against. Instances outside of the subgroup are ignored and left untouched.

### Serializer mapping attributes

`CDMAttributeString` - Translates the data found in json to String

`CDMAttributeBool` - Translates the data found in json to Bool

`CDMAttributeInt` - Translates the data found in json to Int

`CDMAttributeNumber` - Translates the data found in json to NSNumber

`CDMAttributeDouble` - Translates the data found in json to Double

`CDMAttributeFloat` - Translates the data found in json to Float

`CDMAttributeISODate` - Translates the data found in json to NSDate using ISO format - _yyyy-MM-dd'T'HH:mm:ssZZZZZ_ or _yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ_

`CDMAttributeToMany` - Translates the data found in json to NSSet of NSManagedObject

`CDMAttributeToOne` - Translates the data found in json to NSManagedObject

You need to define a callback that returns a serializer for serializing and matching the managed objects when initializing attributes that return managed objects.

### Serializer examples

```swift
// Create serializers for `Department` and `Employee` - both NSManagedObject subclasses
class DepartmentSerializer<T:Department>: CDMSerializer<T> {
    override init() {
        super.init()

        self.identifiers = ["departmentID"]
        self.mapping = [
            "departmentID": CDMAttributeNumber(["id"]),
            "name": CDMAttributeString(["name"]),
        ]
    }
}

class EmployeeSerializer<T:Employee>: CDMSerializer<T> {
    override init() {
        super.init()

        self.identifiers = ["employeeID"]
        self.mapping = [
            "employeeID": CDMAttributeNumber(["id"]),
            "fullName": CDMAttributeString(["user", "name"]),
            "department": CDMAttributeToOne(["department"], serializerCallback: {departmentJSON in 
                let departmentSerializer = DepartmentSerializer()
                // Don't update nor delete the objects in child serializer
                // Just match the department
                departmentSerializer.updateExisting = false
                departmentSerializer.deleteMissing = false

                return departmentSerializer
            }),
        ]
    }
}
```

## Syncing JSON data

```swift
let serializer = EmployeeSerializer()
let jsonData = JSON([
    [
        "id": 1,
        "user": ["id": 5, "name": "Mary"],
        "department": ["id": 2, "name": "iOS development"]
    ],[
        "id": 2,
        "user": ["id": 6, "name": "David"],
        "department": ["id": 2, "name": "iOS development"]
    ]
])

let context = CoreDataManager.sharedInstance.backgroundContext
context.syncData(jsonData, withSerializer: serializer) { (error) -> Void in
    // Sync completed
    // Employees Mary and David have been inserted or updated in core data. Other employees have been deleted
}
```

## Author

Taavi Teska ([Thorgate](http://thorgate.eu/))

## Dependencies

- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)

All the dependencies are automatically installed when using CocoePods

## Credits

CoreDataManager is using some of the ideas from [CoreDataSimpleDemo](https://github.com/iascchen/SwiftCoreDataSimpleDemo) example for managed object contexts

## License

CoreDataManager is available under the MIT license. See the LICENSE file for more info.

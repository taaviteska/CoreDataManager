# CoreDataManager

[![Version](https://img.shields.io/cocoapods/v/CoreDataManager.svg?style=flat)](http://cocoapods.org/pods/CoreDataManager)
[![License](https://img.shields.io/cocoapods/l/CoreDataManager.svg?style=flat)](http://cocoapods.org/pods/CoreDataManager)
[![Platform](https://img.shields.io/cocoapods/p/CoreDataManager.svg?style=flat)](http://cocoapods.org/pods/CoreDataManager)
[![Twitter](https://img.shields.io/badge/twitter-@TaaviTeska-blue.svg?style=flat)](https://twitter.com/TaaviTeska)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

CoreDataManager is available through [CocoaPods](http://cocoapods.org). Install it with the following command:

```bash
$ gem install cocoapods
```

To install CoreDataManager add a file named `Podfile` to the project's root folder with contents similar to:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'CoreDataManager', '~> 0.2'
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
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
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

## Fetching managed objects

```swift
// Array of employees
let employees = mainCtx.managerFor(Employee).array

// Count of employees
let employeeCount = mainCtx.managerFor(Employee).count

// First / last employee
let oldestEmployee = mainCtx.managerFor(Employee).orderBy("age").first
let youngestEmployee = mainCtx.managerFor(Employee).orderBy("age").last
```

## Filtering managed objects

Filter method accepts predicates and can be called with same arguments that a NSPredicate can be initialized

```swift
let youngEmployeeManager = mainCtx.managerFor(Employee).filter("age < 40")

// Young employees
let youngEmployees = youngEmployeeManager.array

// Count of young employees
let youngEmployeeCount = youngEmployeeManager.count
```

## Ordering managed objects

Applying minus sign (-) in front of the attribute will make the ordering descening

```swift
// Ascending array of employees ordered by age
let employeesFromYoungest = mainCtx.managerFor(Employee).orderBy(["age", "name"]).array

// Descending array of employees ordered by age
let employeesFromOldest = mainCtx.managerFor(Employee).orderBy(["-age", "name"]).array
```

## Aggregating managed objects

```swift
// Age of the youngest employee
let ageOfYoungestEmployee = mainCtx.managerFor(Employee).min("age")

// Age of the oldest employee
let ageOfOldestEmployee = mainCtx.managerFor(Employee).max("age")

// Total age of the employees
let totalAgeOfEmployees = mainCtx.managerFor(Employee).sum("age")

// Average age of the employees
let avgAgeOfEmployees = mainCtx.managerFor(Employee).aggregate("average", forKeyPath: "age")
```

## Deleting managed objects

```swift
// Delete employees older than 100
backgroundCtx.performBlock { () -> Void in
    backgroundCtx.managerFor(Employee).filter("age > 100").delete()
    backgroundCtx.save()
}
```

## Serializers

- Will be described soon. Meanwhile you can check tests to get the idea

## Syncing JSON data

- Will be described soon. Meanwhile you can check tests to get the idea

## Author

Taavi Teska ([Thorgate](http://thorgate.eu/))

## Known bugs

- Aggregate methods don't work with in-memory persistent stores (NSInMemoryStoreType). Avoid using CoreDataManager.setupInMemoryStoreCoordinator() when using aggregation helpers

## Dependencies

- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)

## Credits

CoreDataManager is using some of the ideas from [CoreDataSimpleDemo](https://github.com/iascchen/SwiftCoreDataSimpleDemo) example for managed object contexts

## License

CoreDataManager is available under the MIT license. See the LICENSE file for more info.

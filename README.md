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

## Author

Taavi Teska ([Thorgate](http://thorgate.eu/))

## Known bugs

- Aggregate methods don't work with in-memory persistent stores (NSInMemoryStoreType). Avoid using CoreDataManager.setupInMemoryStoreCoordinator() when using aggregation helpers

## Credits

CoreDataManager is using some of the ideas from [CoreDataSimpleDemo](https://github.com/iascchen/SwiftCoreDataSimpleDemo) example for managed object contexts

## License

CoreDataManager is available under the MIT license. See the LICENSE file for more info.

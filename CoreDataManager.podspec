#
# Be sure to run `pod lib lint CoreDataManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "CoreDataManager"
  s.version          = "0.2.0"
  s.summary          = "Helper for Core Data management and syncing data from an JSON API"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = "CoreDataManager makes it easy to operate with managed objects and map them with the objects fetched from any JSON API endpoint."

  s.homepage         = "https://github.com/taaviteska/CoreDataManager"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Taavi Teska" => "taaviteska@gmail.com" }
  s.source           = { :git => "https://github.com/taaviteska/CoreDataManager.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/taaviteska'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'CoreDataManager' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end

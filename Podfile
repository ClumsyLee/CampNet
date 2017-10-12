# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

# Comment the next line if you're not using Swift and don't want to use dynamic frameworks
use_frameworks!

target 'CampNet iOS' do
  # Pods for CampNet iOS
  pod 'BRYXBanner'
  pod 'Charts'
  pod 'DynamicButton'
  pod 'Instabug'
  pod 'SwiftRater', :git => 'https://github.com/ThomasLee969/SwiftRater'
end

target 'CampNetKit' do
  # Pods for CampNetKit
  pod 'Alamofire'
  pod 'CryptoSwift'
  pod 'Kanna'
  pod 'KeychainAccess'
  pod 'NetUtils'
  pod 'PromiseKit'
  pod 'SwiftyBeaver'
  pod 'SwiftyUserDefaults'
  pod 'Yaml'

  target 'CampNet iOS Widget' do
    pod 'Charts'
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
      if ['Kanna', 'Yaml'].include? target.name
          target.build_configurations.each do |config|
              config.build_settings['SWIFT_VERSION'] = '3.2'
          end
      end
  end
end

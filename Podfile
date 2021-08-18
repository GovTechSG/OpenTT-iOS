# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

inhibit_all_warnings!

source 'https://github.com/CocoaPods/Specs.git'

pod 'Firebase/Analytics', '~> 7.1.0'
pod 'Firebase/Functions', '~> 7.1.0'
pod 'Firebase/Storage', '~> 7.1.0'
pod 'Firebase/Crashlytics', '~> 7.1.0'
pod 'Firebase/Auth', '~> 7.1.0'
pod 'Firebase/RemoteConfig', '~> 7.1.0'
pod 'Firebase/Messaging', '~> 7.1.0'
pod 'FirebaseUI/Phone', '~> 10.0.0'
pod 'ZendeskSupportSDK', '~> 5.2.0'
pod 'lottie-ios', '~> 3.2.0'
pod 'SwiftLint', '0.40.2'
pod 'CountryPickerView', '~> 3.2.0'
pod 'RSBarcodes_Swift', '~> 5.1.0'
pod 'SwiftyGif', '~> 5.4.0'

# https://firebase.google.com/docs/ios/setup#available-pods

target 'TraceTogether' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for tracer

end

post_install do |pi|
  pi.pods_project.targets.each do |t|
    t.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods-TraceTogether/Pods-TraceTogether-acknowledgements.plist', 'Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end


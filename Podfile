project "SmartYard.xcodeproj"
platform :ios, '12.0'
inhibit_all_warnings!

source 'https://cdn.cocoapods.org/'
source "https://gitlab.linphone.org/BC/public/podspec.git"

target 'SmartYard' do
  use_frameworks!

  # Networking
  pod 'Moya/RxSwift' 
  pod 'Kingfisher'
  pod 'linphone-sdk'
  pod 'WKCookieWebView', '~> 2.0'
  pod 'WebRTC-lib'
  
  # Reactive
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxViewController'
  pod 'RxDataSources'

  # Utilities
  pod 'SwiftLint'#, '0.35'
  pod 'SwifterSwift', :git => 'https://github.com/SwifterSwift/SwifterSwift.git', :branch => 'master'
  
  # UI
  pod 'Cartography'
  pod 'PMNibLinkableView'
  pod 'TouchAreaInsets'
  pod 'PinLayout'
  pod 'SSCustomTabbar', :git => 'https://github.com/rosteleset/SSCustomTabbar.git', :branch => 'feature/add-animation-options'
  pod 'TPKeyboardAvoiding'
  pod 'JGProgressHUD'
  pod 'SkeletonView' #, '1.7'
  pod 'SearchTextField'
  pod 'SHSPhoneComponent'
  pod 'Parchment'#, '2.2.0'
  pod 'lottie-ios'
  
  # Calendar
  pod 'JTAppleCalendar'
  pod 'PopOverDatePicker', :git => 'https://github.com/rosteleset/PopOverDatePicker.git', :branch => 'timezoneSupport'
  
  # Map
  pod 'MapboxMaps'
  
  # Analytics
  pod 'FirebaseCrashlytics', '10.29.0'
  pod 'FirebaseAnalytics', '10.29.0'
  
  # Push Notifications
  pod 'FirebaseMessaging'
  
  # Routing
  pod 'XCoordinator'
  pod 'XCoordinator/RxSwift'
  
  # Chat
  pod 'OnlineChatSdk', :git => 'https://github.com/rosteleset/OnlineChatSdk-Swift.git', :branch => 'feature/build-fix'
  
end

target 'SmartYardWidget' do
  use_frameworks!

  # Reactive
  pod 'RxSwift'
  pod 'RxCocoa'

end

target 'SmartYardIntents' do
  use_frameworks!
  
  pod 'SwifterSwift', :git => 'https://github.com/SwifterSwift/SwifterSwift.git', :branch => 'master'
end


post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
            
            if config.name == 'Release'
                config.build_settings['SWIFT_COMPILATION_MODE'] = 'wholemodule'
            end
        end
    end
end

post_integrate do |installer|
  # Removing duplicates in output file lists.
  # Liblinphone-sdk since version 5.2.*  produces duplcate lines in this files.
  # It seems like a bug in liblinphone-sdk podspec or in cocoapods itself.
  puts "!!! Removing duplicates from output-files.xcfilelist  !!!"
  IO.write(File.join(Dir.pwd,'Pods/Target Support Files/Pods-SmartYard/Pods-SmartYard-frameworks-Release-output-files.xcfilelist'),
  IO.readlines(File.join(Dir.pwd,'Pods/Target Support Files/Pods-SmartYard/Pods-SmartYard-frameworks-Release-output-files.xcfilelist'), chomp: true).uniq.join("\n"))
  IO.write(File.join(Dir.pwd,'Pods/Target Support Files/Pods-SmartYard/Pods-SmartYard-frameworks-Debug-output-files.xcfilelist'),
  IO.readlines(File.join(Dir.pwd,'Pods/Target Support Files/Pods-SmartYard/Pods-SmartYard-frameworks-Debug-output-files.xcfilelist'), chomp: true).uniq.join("\n"))
end

platform :ios, '11.0'
inhibit_all_warnings!

source 'https://cdn.cocoapods.org/'
source "https://gitlab.linphone.org/BC/public/podspec.git"

target 'SmartYard' do
  use_frameworks!

  # Networking
  pod 'Moya/RxSwift' 
  pod 'Kingfisher'
  pod 'linphone-sdk' #, '4.4.28'
  
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
  pod 'PopOverDatePicker'
  
  # Map
  pod 'MapboxMaps', '10.2.0'
  
  # Analytics
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'
  pod 'YandexMobileMetrica'
  
  # Push Notifications
  pod 'Firebase/Messaging'
  
  # Routing
  pod 'XCoordinator'
  pod 'XCoordinator/RxSwift'
  
  # Chat
  pod 'OnlineChatSdk', :git => 'https://github.com/rosteleset/OnlineChatSdk-Swift.git', :branch => 'feature/build-fix'
  # YouTube
  pod "youtube-ios-player-helper-swift"
  
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
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
            
            if config.name == 'Release'
                config.build_settings['SWIFT_COMPILATION_MODE'] = 'wholemodule'
            end
        end
    end
end

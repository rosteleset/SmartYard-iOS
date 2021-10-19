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
  pod 'SwifterSwift'#, '4.6'
  
  # UI
  pod 'Cartography'
  pod 'PMNibLinkableView'
  pod 'TouchAreaInsets'
  pod 'PinLayout'
  pod 'SSCustomTabbar', :git => 'https://git.lanta.me/LanTa/SSCustomTabbar.git', :branch => 'feature/add-animation-options'
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
  pod 'Mapbox-iOS-SDK', '5.5.0' # пришлось опускать версию, т.к. были ошибки в Crashlytics в MapboxMobileEvents
  
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
  pod 'OnlineChatSdk', :git => 'https://git.lanta.me/LanTa/OnlineChatSdk-Swift.git', :branch => 'feature/build-fix'
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
  
  pod 'SwifterSwift'
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
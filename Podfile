platform :ios, '11.0'
inhibit_all_warnings!

source 'https://github.com/cocoapods/specs.git'
source "https://gitlab.linphone.org/BC/public/podspec.git"

target 'SmartYard' do
  use_frameworks!

  # Networking
  pod 'Moya/RxSwift'
  pod 'Kingfisher'
  pod 'linphone-sdk' , '> 4.4.0-alpha'
  
  # Reactive
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxViewController'
  pod 'RxDataSources'

  # Utilities
  pod 'SwiftLint', '0.35'
  pod 'SwifterSwift', '4.6'
  
  # UI
  pod 'Cartography'
  pod 'PMNibLinkableView'
  pod 'TouchAreaInsets'
  pod 'PinLayout'
  pod 'SSCustomTabbar', :git => 'https://github.com/MadBrains/SSCustomTabbar.git', :branch => 'feature/add-animation-options'
  pod 'TPKeyboardAvoiding'
  pod 'JGProgressHUD'
  pod 'SkeletonView', '1.7'
  pod 'SearchTextField'

  # Map
  pod 'Mapbox-iOS-SDK'
  
  # Analytics
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'Firebase/Analytics'
  
  # Push Notifications
  pod 'Firebase/Messaging'
  
  # Routing
  pod 'XCoordinator'
  pod 'XCoordinator/RxSwift'
  
end

post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        if config.name == 'Release'
            config.build_settings['SWIFT_COMPILATION_MODE'] = 'wholemodule'
        end
    end
end

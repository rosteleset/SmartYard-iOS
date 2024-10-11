inhibit_all_warnings!

source 'https://cdn.cocoapods.org/'
# source 'https://github.com/CocoaPods/Specs.git'
source "https://gitlab.linphone.org/BC/public/podspec.git"
source 'https://git.yoomoney.ru/scm/sdk/cocoa-pod-specs.git'

def common_pods
  # Networking
  pod 'Moya/RxSwift' 
  pod 'Kingfisher'
  pod 'linphone-sdk' #, '4.4.28'
  pod 'WKCookieWebView', '~> 2.0'
  
  # Reactive
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxViewController'
  pod 'RxDataSources'

  # Utilities
  pod 'SwiftLint' #, :source => 'https://cdn.cocoapods.org/' 
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
  pod 'Parchment' #, '2.2.0'
  pod 'lottie-ios', '4.4.1'
  pod 'MessageKit'
  pod 'DropDown'
  
  # Calendar
  pod 'JTAppleCalendar' #, '8.0.5'
  pod 'PopOverDatePicker'
  
  # Map
  pod 'MapboxMaps' #, '11.2.0'
  
  # Routing
  pod 'XCoordinator'
  pod 'XCoordinator/RxSwift'
  
  # Chat
  # pod 'OnlineChatSdk', :git => 'https://github.com/rosteleset/OnlineChatSdk-Swift.git', :branch => 'feature/build-fix'
  
end

target 'SmartYard' do
  platform :ios, '14.0'
  use_frameworks!

  common_pods

  # Analytics
  pod 'FirebaseCrashlytics'
  pod 'FirebaseAnalytics' #, '~> 11.0.0'
  # pod 'YandexMobileMetrica'
  
  # Push Notifications
  pod 'FirebaseMessaging'
  
  # YooKassa
  #pod 'FunctionalSwift', '1.8.0', :source => 'https://git.yoomoney.ru/scm/sdk/cocoa-pod-specs.git'
  #pod 'TMXProfiling', '1.0.1', :source => 'https://git.yoomoney.ru/scm/sdk/cocoa-pod-specs.git'
  #pod 'TMXProfilingConnections', '1.0.1', :source => 'https://git.yoomoney.ru/scm/sdk/cocoa-pod-specs.git'
  #pod 'ThreatMetrixAdapter', '3.3.6', :source => 'https://git.yoomoney.ru/scm/sdk/cocoa-pod-specs.git'
  #pod 'YooKassaPaymentsApi', '2.11.0', :source => 'https://git.yoomoney.ru/scm/sdk/cocoa-pod-specs.git'
  #pod 'YooKassaWalletApi', '2.3.2', :source => 'https://git.yoomoney.ru/scm/sdk/cocoa-pod-specs.git'
  #pod 'YooMoneyCoreApi', '2.1.0', :source => 'https://git.yoomoney.ru/scm/sdk/cocoa-pod-specs.git'
  #pod 'YooMoneyUI', '5.35.2', :source => 'https://git.yoomoney.ru/scm/sdk/cocoa-pod-specs.git'
  pod 'YooKassaPayments', :git => 'https://git.yoomoney.ru/scm/sdk/yookassa-payments-swift.git', :tag => '7.2.0'
  
  # SBP
  pod 'TASDKCore'
  pod 'TASDKUI'
end

#target 'SmartYardOld' do
#  platform :ios, '12.3'
#  use_frameworks!

  #common_pods

 # Analytics
  #pod 'FirebaseCrashlytics'
  #pod 'FirebaseAnalytics', '~> 10.29.0'
  # pod 'YandexMobileMetrica'
  
  # Push Notifications
  #pod 'FirebaseMessaging'
 
  # SBP
  #pod 'TASDKCore'
  #pod 'TASDKUI'
#end

target 'SmartYardWidget' do
  platform :ios, '14.0'
  use_frameworks!

  # Reactive
  pod 'RxSwift'
  pod 'RxCocoa'

end

target 'SmartYardIntents' do
  platform :ios, '14.0'
  use_frameworks!
  
  pod 'SwifterSwift', :git => 'https://github.com/SwifterSwift/SwifterSwift.git', :branch => 'master'
end

PodsWithConflict = [
#  'MessageKit',
#  'YooMoneyUI'
#  'YooKassaPayments'
]

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          if target.name == 'YooKassaPayments'
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
          else 
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0' #'12.3'
          end
 
          if config.name == 'Release'
              config.build_settings['SWIFT_COMPILATION_MODE'] = 'wholemodule'
          end

        end
    end
end

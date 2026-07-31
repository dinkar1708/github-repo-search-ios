platform :ios, '17.0'

# Global settings
use_frameworks!
inhibit_all_warnings!

target 'github_repo_search_iOS_app' do
  # Example pods (uncomment to use)

  # Networking
  # pod 'Alamofire', '~> 5.9'

  # Image loading and caching
  # pod 'Kingfisher', '~> 8.1'

  # Keychain wrapper for secure storage
  # pod 'KeychainAccess', '~> 4.2'

  # Lottie animations
  # pod 'lottie-ios', '~> 4.5'

  # Firebase (Analytics & Crashlytics)
  # pod 'FirebaseAnalytics', '~> 11.0'
  # pod 'FirebaseCrashlytics', '~> 11.0'

  target 'github_repo_search_iOS_app_UnitTests' do
    inherit! :search_paths
    # Test dependencies
  end

  target 'github_repo_search_iOS_app_IntegrationTests' do
    inherit! :search_paths
    # Integration test dependencies
  end

  target 'github_repo_search_iOS_app_UITests' do
    # UI test dependencies
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    end
  end
end

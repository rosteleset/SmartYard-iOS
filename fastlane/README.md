fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
### firebase_flutter
```
fastlane firebase_flutter
```


----

## iOS
### ios add_device
```
fastlane ios add_device
```

### ios fabric
```
fastlane ios fabric
```
Submit a new Beta Build to Fabric

This will also make sure the profile is up to date

Parameters:

:scheme - schema(s) to build. May be String or Array with multiple schemas

:configuration - configuration to build (Debug, Release, etc)

:export_method - ad-hoc, app-store, enterprise

:test_groups - test groups in Fabric to test build for

:export_options - additional options for build_ios_app (gym lane)

:xcode_version - specify Xcode version if needed

:force_full_cert_sync - force-load every provisioning profile and certificate bound to current project
### ios firebase
```
fastlane ios firebase
```
Submit a new Build to Firebase

This will also make sure the profile is up to date

Parameters:

:scheme - schema(s) to build. May be String or Array with multiple schemas

:firebase_app_id - Firebase App ID

:configuration - configuration to build (Debug, Release, etc)

:export_method - ad-hoc, app-store, enterprise

:test_groups - test groups in Firebase to test build for

:export_options - additional options for build_ios_app (gym lane)

:xcode_version - specify Xcode version if needed

:force_full_cert_sync - force-load every provisioning profile and certificate bound to current project
### ios tf
```
fastlane ios tf
```
Submit a new Build to TestFlight (ready for AppStore)

This will also make sure the profile is up to date

Parameters:

:scheme - schema(s) to build. May be String or Array with multiple schemas

:configuration - configuration to build (Debug, Release, etc)

:export_method - ad-hoc, app-store, enterprise

:app_store_connect_team_id - Team ID in App Store Connect (It is not the one from Provisioning Profiles!)

:export_options - additional options for build_ios_app (gym lane)

:xcode_version - specify Xcode version if needed

:force_full_cert_sync - force-load every provisioning profile and certificate bound to current project
### ios sync_certs
```
fastlane ios sync_certs
```
Get all certificates and provisionings

Can be called as not readonly: 'fastlane sync_certs update:true'
### ios sync_certs_for_scheme
```
fastlane ios sync_certs_for_scheme
```
Get certificates and provisionings for selected scheme and configuration
### ios archive_release_ios_after_flutter
```
fastlane ios archive_release_ios_after_flutter
```

### ios firebase_release
```
fastlane ios firebase_release
```

### ios tf_release
```
fastlane ios tf_release
```


----

## Android
### android fabric
```
fastlane android fabric
```
Submit a new Beta Build to Fabric

Parameters:

:flavor - for example, a (demo) product flavor can specify different features and device requirements

:build_type - The assembly type is used to set the assembly settings (Debug, Release)

:test_groups - test groups in Fabric to test build for

:gradle_path - path where gradle is located
### android firebase
```
fastlane android firebase
```
Submit a new Build to Firebase

Parameters:

:firebase_app_id - Firebase App ID

:flavor - for example, a (demo) product flavor can specify different features and device requirements

:build_type - The assembly type is used to set the assembly settings (Debug, Release)

:test_groups - test groups in Fabric to test build for

:gradle_path - path where gradle is located
### android googleplay
```
fastlane android googleplay
```
Submit a upload to Google Play Beta

Parameters:

:flavor - for example, a (demo) product flavor can specify different features and device requirements

:gradle_path - path where gradle is located

:key_path - path where google play json key

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

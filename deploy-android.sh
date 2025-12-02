# deploy android
cd android
fastlane build_aab
fastlane upload_internal
fastlane upload_production

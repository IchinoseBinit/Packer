# deploy android
# build_aab now creates the Shorebird release (scripts/build_bundle.sh) before fastlane uploads it
cd android
fastlane build_aab
fastlane upload_internal
fastlane upload_production

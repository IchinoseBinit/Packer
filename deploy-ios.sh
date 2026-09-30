# deploy ios
# build_release runs scripts/build_ipa.sh (production, obfuscated, app-store signed)
# then beta uploads ./gen/fasto-packer.ipa to TestFlight.
#
# Needs an Apple ID that can sign for team DBJFG97478:
#   FASTLANE_USER=you@example.com ./deploy-ios.sh
cd ios
fastlane build_release
fastlane beta

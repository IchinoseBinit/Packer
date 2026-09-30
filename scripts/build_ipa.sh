#!/bin/bash
set -euo pipefail

# Production iOS build.
#
# Mirrors scripts/build_bundle.sh: production API, obfuscated, output in ./gen.
# Produces an App Store signed .ipa ready for TestFlight.
#
# Requires an Apple Distribution certificate and an App Store provisioning
# profile for com.np.fasto.packer in team DBJFG97478. Create them with
# `cd ios && fastlane certs` if the build fails to export.

echo "Building... iOS production"

cd "$(dirname "$0")/.."

mkdir -p gen

flutter build ipa \
  --obfuscate \
  --split-debug-info=./ \
  --release \
  --dart-define=APIType=production \
  --export-method app-store

IPA=$(find build/ios/ipa -name "*.ipa" -maxdepth 1 | head -1)

if [ -z "$IPA" ]; then
  echo "ERROR: no .ipa produced. The archive step may have succeeded while"
  echo "export failed - check for missing distribution signing above."
  exit 1
fi

mv "$IPA" ./gen/fasto-packer.ipa
echo "Built ./gen/fasto-packer.ipa"

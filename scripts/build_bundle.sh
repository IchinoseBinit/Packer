#!/bin/bash
echo $1
pwd
cd ../..
pwd

# for removing version line from pubpsec.yml in linux or window
# sed -i '/version:/d' pubspec.yaml

# Remove existing version line (macOS compatible)
sed -i '' '/^version:/d' pubspec.yaml

echo '\n'

echo -e version: 1.0.$1+$1 >> pubspec.yaml

echo "Building AAB... version $1"


mkdir -p gen

flutter build appbundle --obfuscate --split-debug-info=./ --release --dart-define=APIType=production

cp ./build/app/outputs/bundle/release/app-release.aab ./gen/fasto-packer.aab


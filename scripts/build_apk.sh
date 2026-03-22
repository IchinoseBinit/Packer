#!/bin/bash

echo "Building... version"

mkdir -p gen

flutter build apk --obfuscate --split-debug-info=./ --release --dart-define=APIType=production



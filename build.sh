echo "Building your app"

flutter build appbundle --release --dart-define=APIType=production

mkdir -p ./gen/

mv ./build/app/outputs/bundle/release/app-release.aab ./gen/fasto-packer.aab


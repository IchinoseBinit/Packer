echo "Building your app"

flutter build apk --release --dart-define=APIType=staging

mkdir -p ./gen/

mv ./build/app/outputs/apk/release/app-release.apk ./gen/fasto-packer.apk


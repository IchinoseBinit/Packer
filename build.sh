echo "Building your app"

flutter build apk --no-tree-shake-icons --release --target=lib/main.dart --dart-define=APIType=production

mkdir -p ./gen/

mv ./build/app/outputs/flutter-apk/app-release.apk ./gen/fasto-packer.apk


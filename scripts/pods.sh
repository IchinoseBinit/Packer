cd ios

rm -rf .symlinks/

rm -rf Pods

rm -rf Podfile.lock

pod install

cd ..

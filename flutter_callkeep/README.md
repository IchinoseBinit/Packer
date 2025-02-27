# callkeep

Showing incoming call notification/screen using iOS CallKit and Android Custom UI for Flutter

Web is supported but user must build their own incoming call UI in Flutter, see below.

## Native setup

flutter_callkeep requires the following permissions.

### Android

in `AndroidManifest.xml`, set `launchMode` to `singleInstance` for our main activity.

```xml
 <manifest...>
    
    ...
    <activity ...
    android:name=".MainActivity"
    android:launchMode="singleInstance">
    ...
    ...

</manifest>
```

on Android 13+ you need to ask for Notifications permission in order to show incoming call notification.

You can either achieve that using firebase messaging:
```dart
final firebaseMessaging = FirebaseMessaging.instance;
final notificationSettings = await firebaseMessaging.getNotificationSettings();
final isPermissionDenied =
    notificationSettings.authorizationStatus == AuthorizationStatus.denied;

...
// We request  Android 13 and above permission as it is denied by default and we have to ask
// But for iOS we only ask if permission is not denied, as it defaults to notDetermined on first boot
final isAndroid13OrAbove = (UniversalPlatform.isAndroid &&
((await DeviceInfoPlugin().androidInfo).version.sdkInt) >= 33);

// TODO(any): maybe show a custom UI if permission is denied for all platforms
// to get through how important notification permissions are
final shouldPrompt =
(isAndroid13OrAbove && isPermissionDenied) || !isPermissionDenied;

if(shouldPrompt){
final settings = await firebaseMessaging.requestPermission();

}
...

```

or by using the [`permission_handler` package](https://pub.dev/packages/permission_handler)


### iOS
in `Info.plist`

```
<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
    <string>remote-notification</string>
    <string>voip</string>
</array>
```

Then you need to update `AppDelegate.swift` to follow the example for handling PushKit as push handling must be done through native iOS code due to [iOS 13 PushKit VoIP restrictions](https://developer.apple.com/documentation/pushkit/pkpushregistrydelegate/2875784-pushregistry).

```swift
import UIKit
import PushKit
import Flutter
import flutter_callkeep

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        //Setup VOIP
        let mainQueue = DispatchQueue.main
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Handle updated push credentials
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        print(credentials.token)
        let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        print(deviceToken)
        //Save deviceToken to your server
        SwiftCallKeepPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("didInvalidatePushTokenFor")
        SwiftCallKeepPlugin.sharedInstance?.setDevicePushTokenVoIP("")
    }
    
    // Handle incoming pushes
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("didReceiveIncomingPushWith")
        guard type == .voIP else { return }
        
        let id = payload.dictionaryPayload["id"] as? String ?? ""
        let callerName = payload.dictionaryPayload["callerName"] as? String ?? ""
        let userId = payload.dictionaryPayload["callerId"] as? String ?? ""
        let handle = payload.dictionaryPayload["handle"] as? String ?? ""
        let isVideo = payload.dictionaryPayload["isVideo"] as? Bool ?? false
        
        let data = flutter_callkeep.Data(id: id, callerName: callerName, handle: handle, hasVideo: isVideo)
        //set more data
        data.extra = ["userId": callerId, "platform": "ios"]
        data.appName = "Done"
        //data.iconName = ...
        //data.....
        SwiftCallKeepPlugin.sharedInstance?.displayIncomingCall(data, fromPushKit: true)
    }   
}
```

## Usage

### Dependency:
Add the dependency manually to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter_callkeep: ^(latest_version)
```

or run:

```bash
flutter pub add flutter_callkeep
```

### Setup: 

You need to configure the package before displaying incoming calls: 

```dart
void configureCallkeep() {
  final config = CallKeepConfig(
    appName: 'CallKeep',
    // Other plugin configurations
    android: CallKeepAndroidConfig(
      // Android configuration
    ),
    ios: CallKeepIosConfig(
      // iOS configuration
    ),
    // Headers if needed
    headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
  );
  CallKeep.instance.configure(config);
}
```

### Display incoming call:

```dart
final data = CallEvent(
  uuid: uuid,
  callerName: 'Test User',
  handle: '0123456789',
  hasVideo: false,
  duration: 30000,
  extra: <String, dynamic>{'userId': '1a2b3c4d'},
);

await CallKeep.instance.displayIncomingCall(data);
```

### Show missed call notification (Android only and may be removed in later versions):

```dart
final data = CallEvent(
  uuid: uuid,
  callerName: 'Test User',
  handle: '0123456789',
  hasVideo: false,
  duration: 30000,
  extra: <String, dynamic>{'userId': '1a2b3c4d'},
);

await CallKeep.instance.showMissCallNotification(data);
```

### Start an outgoing call:

```dart
final data = CallEvent(
  uuid: uuid,
  callerName: 'Test User',
  handle: '0123456789',
  hasVideo: false,
  duration: 30000,
  extra: <String, dynamic>{'userId': '1a2b3c4d'},
);

CallKeep.instance.startCall(data);
```

### Handling events and showing custom UI (Web):

You need to pass your callbacks for each event to the plugin's `handler` property

if the platform doesn't support incoming call display - such as CallKit for iOS or custom activity for Android -, 
you can show your own incoming call UI using the `onCallIncoming` event.

We can check first if the plugin is displaying incoming call UI or not using `CallKeep.instance.isIncomingCallDisplayed` and show our custom UI accordingly.

```dart
 Future<void> setEventHandler() async {
  CallKeep.instance.handler = CallEventHandler(
    onCallIncoming: (event) {
      print('call incoming: ${event.toMap()}');
      if (!CallKeep.instance.isIncomingCallDisplayed) {
        showAdaptiveDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("Incoming Call"),
                content: Text("Incoming call from ${event.callerName}"),
                actions: [
                  TextButton(
                    onPressed: () {
                      CallKeep.instance.acceptCall(event.uuid);
                      Navigator.pop(context);
                    },
                    child: Text("Accept"),
                  ),
                  TextButton(
                    onPressed: () {
                      CallKeep.instance.endCall(event.uuid);
                      Navigator.pop(context);
                    },
                    child: Text("Decline"),
                  ),
                ],
              );
            });
      }
    },
    onCallStarted: (event) {
      print('call started: ${event.toMap()}');
    },
    onCallEnded: (event) {
      print('call ended: ${event.toMap()}');
    },
    onCallAccepted: (event) {
      print('call answered: ${event.toMap()}');
      NavigationService.instance
          .pushNamedIfNotCurrent(AppRoute.callingPage, args: event.toMap());
    },
    onCallDeclined: (event) async {
      print('call declined: ${event.toMap()}');
    },
  );
}
```

### Customization (Android):

You can customize background color and add localizations to text through adding the values to your '{{yourApp}}/android/app/src/main/res/values' and '{{yourApp}}/android/app/src/main/res/values-{{languageCode}}' for localizations.

The main values are:
in `colors.xml`
```xml
    <!-- A hex color value to be displayed on the top part of the custom incoming call UI --> 
    <color name="incoming_call_bg_color">#80ffffff</color>
```

in `strings.xml`
```xml
    <!-- Accept button call text, useful for localization --> 
    <string name="accept_text">Accept</string>
    <!-- Decline button call text, useful for localization --> 
    <string name="decline_text">Decline</string>
    <!-- Missed call text, useful for localization --> 
    <string name="text_missed_call">Missed call</string>
    <!-- Callback button text, useful for localization --> 
    <string name="text_call_back">Call back</string>
    <!-- Incoming call custom UI header, useful for localization -->
    <!-- This can be set from Flutter as well when displaying incoming call --> 
    <string name="call_header">Call from CallKeep</string>
```
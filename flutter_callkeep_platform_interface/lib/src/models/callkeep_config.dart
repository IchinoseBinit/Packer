import 'package:flutter_callkeep_platform_interface/flutter_callkeep_platform_interface.dart';

/// Holds the configuration for CallKeep plugin
class CallKeepConfig {
  /// App's name, used for display inside CallKit.
  final String appName;

  /// A function that is the base for [CallKeepConfig.contentTitle]
  ///
  /// Good example would be "Call from $callerName" or "Call from $appName"
  ///
  /// The argument passed to it would be the [callerName]
  /// or [appName] if the aforementioned is `null`
  final String Function(String argument)? contentTitle;

  /// Text Accept to be shown for the user to accept the call
  final String acceptText;

  /// Text Decline to be shown for the user to decline the call
  final String declineText;

  /// Text Missed Call to be shown for the user to indicate a missed call
  final String missedCallText;

  /// Text Call Back to be shown for the user to call back after a missed call
  final String callBackText;

  /// Avatar's URL used for display for incoming calls on Android.
  final String? avatar;

  /// Any data for custom header avatar/background image.
  final Map<String, dynamic>? headers;

  /// Android configuration needed to customize the UI.
  final CallKeepAndroidConfig android;

  /// iOS configuration needed for CallKit.
  final CallKeepIosConfig ios;

  CallKeepConfig({
    required this.appName,
    required this.ios,
    required this.android,
    this.contentTitle,
    this.acceptText = 'Accept',
    this.declineText = 'Decline',
    this.missedCallText = 'Missed call',
    this.callBackText = 'Call back',
    this.avatar,
    this.headers,
  });

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      if (contentTitle != null) 'contentTitle': contentTitle!(appName),
      'acceptText': acceptText,
      'declineText': declineText,
      'missedCallText': missedCallText,
      'callBackText': callBackText,
      if (avatar != null) 'avatar': avatar,
      if (headers != null) 'headers': headers ?? {},
      'ios': ios.toMap(),
      'android': android.toMap(),
    };
  }
}

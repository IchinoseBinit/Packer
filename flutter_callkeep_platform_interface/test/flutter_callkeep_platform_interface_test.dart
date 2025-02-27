import 'package:flutter/services.dart';
import 'package:flutter_callkeep_platform_interface/flutter_callkeep_platform_interface.dart';
import 'package:flutter_callkeep_platform_interface/method_channel_callkeep.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelCallKeep', () {
    final log = <MethodCall>[];
    late MethodChannelCallKeep methodChannelCallKeep;

    setUp(() async {
      methodChannelCallKeep = MethodChannelCallKeep();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannelCallKeep.methodChannel,
        (MethodCall methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'displayIncomingCall':
            case 'showMissCallNotification':
            case 'startCall':
            case 'endCall':
            case 'endAllCalls':
            case 'acceptCall':
              return null;
            case 'activeCalls':
              return [
                {'id': '1', 'handle': 'test call'}
              ];
            case 'getDevicePushTokenVoIP':
              return 'voip-token';
            default:
              return null;
          }
        },
      );
      log.clear();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        MethodChannel(methodChannelCallKeep.eventChannel.name),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'listen':
              await TestDefaultBinaryMessengerBinding
                  .instance.defaultBinaryMessenger
                  .handlePlatformMessage(
                methodChannelCallKeep.eventChannel.name,
                methodChannelCallKeep.eventChannel.codec.encodeSuccessEnvelope({
                  'event': 'callEvent',
                  'type': 'callType',
                }),
                (_) {},
              );
              break;
            case 'cancel':
            default:
              return null;
          }
          return null;
        },
      );
    });

    test('displayIncomingCall', () async {
      final callEvent = CallEvent(uuid: 'test-uuid', duration: 180.0);

      await methodChannelCallKeep.displayIncomingCall(callEvent);

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'displayIncomingCall',
            arguments: {
              'id': 'test-uuid',
              'callerName': null,
              'handle': null,
              'hasVideo': false,
              'duration': 180.0,
              'isAccepted': false,
              'extra': {},
            },
          ),
        ],
      );
    });

    test('showMissCallNotification', () async {
      final callEvent = CallEvent(uuid: 'test-uuid', duration: 180.0);

      await methodChannelCallKeep.showMissCallNotification(callEvent);

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'showMissCallNotification',
            arguments: {
              'id': 'test-uuid',
              'callerName': null,
              'handle': null,
              'hasVideo': false,
              'duration': 180.0,
              'isAccepted': false,
              'extra': {},
            },
          ),
        ],
      );
    });

    test('startCall', () async {
      final callEvent = CallEvent(uuid: 'test-uuid', duration: 180.0);

      await methodChannelCallKeep.startCall(callEvent);

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'startCall',
            arguments: {
              'id': 'test-uuid',
              'callerName': null,
              'handle': null,
              'hasVideo': false,
              'duration': 180.0,
              'isAccepted': false,
              'extra': {},
            },
          ),
        ],
      );
    });

    test('endCall', () async {
      const uuid = 'test-uuid';

      await methodChannelCallKeep.endCall(uuid);

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'endCall',
            arguments: {'id': uuid},
          ),
        ],
      );
    });

    test('endAllCalls', () async {
      await methodChannelCallKeep.endAllCalls();

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'endAllCalls',
            arguments: null,
          ),
        ],
      );
    });

    test('activeCalls', () async {
      final result = await methodChannelCallKeep.activeCalls();

      expect(result.length, 1);
      expect(result.first.uuid, '1');
      expect(result.first.handle, 'test call');
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'activeCalls',
            arguments: null,
          ),
        ],
      );
    });

    test('getDevicePushTokenVoIP', () async {
      final result = await methodChannelCallKeep.getDevicePushTokenVoIP();

      expect(result, 'voip-token');
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'getDevicePushTokenVoIP',
            arguments: null,
          ),
        ],
      );
    });

    test('acceptCall', () async {
      const uuid = 'test-uuid';

      await methodChannelCallKeep.acceptCall(uuid);

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'acceptCall',
            arguments: {'id': uuid},
          ),
        ],
      );
    });

    test('eventChannel listen', () async {
      final eventStream =
          methodChannelCallKeep.eventChannel.receiveBroadcastStream();
      final event = await eventStream.first;

      expect(event, isNotNull);
      expect(event, containsPair('event', 'callEvent'));
      expect(event, containsPair('type', 'callType'));
    });
  });
}

import 'dart:async';

import 'package:galli_map/galli_map.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'location_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription<Position>? _locationSubscription;
  StreamController<String>? _messageStreamController;
  final LocationService _locationService = LocationService();

  String? packerId;

  Stream<String> get messageStream {
    _messageStreamController ??= StreamController<String>.broadcast();
    return _messageStreamController!.stream;
  }


  void disconnect() {
    _channel?.sink.close();
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _messageStreamController?.close();
  }

  void dispose() {
    disconnect();
  }
}

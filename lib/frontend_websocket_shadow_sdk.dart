library frontend_websocket_shadow_sdk;

import 'dart:convert';
import 'dart:developer';

import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:stomp_dart_client/stomp_handler.dart';

export 'package:stomp_dart_client/stomp.dart';
export 'package:stomp_dart_client/stomp_config.dart';
export 'package:stomp_dart_client/stomp_frame.dart';
export 'package:stomp_dart_client/stomp_handler.dart';

/// A class representing a subscription to a topic.
class Subscription {
  String destination;
  Function(StompFrame frame) callback;
  StompUnsubscribe? unsubscribeFn;

  Subscription(this.destination, this.callback);
}

/// A client for connecting to the Cereb Websocket Shadow SDK.
/// ```dart
/// final client = CerebWebsocketShadowSdk(
///   url: "https://dev-api.cereb.ai/v1/ws/shadow_websocket",
///   path: "/user/topic/shadow_websocket",
///   id: "A791716517900154M",
/// );
/// client.connect();
/// client.subscribe(
///   '/user/topic/shadow_websocket',
///   (StompFrame frame) {
///     log(frame.body ?? 'null');
///   },
/// );
/// client.send('test');
/// client.unsubscribe('/user/topic/shadow_websocket');
/// client.disconnect();
/// ```
class CerebWebsocketShadowSdk {
  late StompClient _stompClient;
  final String _url;
  final String _id;
  final String _path;
  final reconnectAttempts = 5;
  final reconnectDelay = const Duration(seconds: 5);
  bool isConnected = false;
  StompUnsubscribe? _unsubscribeFn;
  final cerebWebsocketIdKey = "cereb-websocket-id";
  final cerebWebsocketPathKey = "cereb-websocket-path";
  // 存储每个主题的回调函数列表
  List<Subscription> _subscriptions = [];

  /// A client for connecting to the Cereb Websocket Shadow SDK.<br/>
  ///  **path is topic**<br/>
  /// ```dart
  /// final client = CerebWebsocketShadowSdk(
  ///   url: "https://dev-api.cereb.ai/v1/ws/shadow_websocket",
  ///   path: "/user/topic/shadow_websocket",
  ///   id: "A791716517900154M",
  /// );
  /// client.connect();
  /// client.subscribe(
  ///   '/user/topic/shadow_websocket',
  ///   (StompFrame frame) {
  ///     log(frame.body ?? 'null');
  ///   },
  /// );
  /// client.send('test');
  /// client.unsubscribe('/user/topic/shadow_websocket');
  /// client.disconnect();
  /// ```
  CerebWebsocketShadowSdk({
    required String url,

    /// path == topic
    required String path,
    required String id,
  })  : _url = url,
        _path = path,
        _id = id {
    _stompClient = _getStompClient(_id, _path);
  }

  void connect() {
    _stompClient.activate();
  }

  void subscribe(String destination, Function(StompFrame frame) callback) {
    final subscription = Subscription(destination, callback);
    _subscriptions.add(subscription);
    if (isConnected) _subscribeSingle(subscription);
  }

  void send(String message) {
    _stompClient.send(destination: _path, body: message);
  }

  void unsubscribe(String destination) {
    _subscriptions.removeWhere(
      (subscription) => subscription.destination == destination,
    );
  }

  void disconnect() {
    for (var subscription in _subscriptions) {
      if (subscription.unsubscribeFn != null) {
        subscription.unsubscribeFn!(
          unsubscribeHeaders: {cerebWebsocketIdKey: _id},
        );
      }
    }
    _stompClient.deactivate();
  }

  void _onConnect(StompFrame stompFrame) {
    log('${DateTime.now()} >>>>>> cereb websocket connected......');
    isConnected = true;
    _subscribeAll();
  }

  void _subscribeSingle(Subscription subscription) {
    subscription.unsubscribeFn = _stompClient.subscribe(
      destination: subscription.destination,
      callback: subscription.callback,
    );
  }

  void _subscribeAll() {
    for (var subscription in _subscriptions) {
      _subscribeSingle(subscription);
    }
  }

  static Map<String, dynamic>? decodeMessageToJson(String? message) {
    if (message == null) return null;
    final data = jsonDecode(message);
    final content = data['content'] as String?;
    final json = jsonDecode(content?.replaceAll(RegExp(r'\n'), '\\n') ?? '{}');
    return json;
  }

  StompClient _getStompClient(
    String cerebWebsocketId,
    String cerebWebsocketPath,
  ) {
    int attempts = 0;
    StompClient? client;
    client = StompClient(
      config: StompConfig.SockJS(
        url: _url,
        onConnect: (StompFrame frame) {
          isConnected = true;
          attempts = 0;
          _onConnect(frame);
        },
        beforeConnect: () async {
          log('${DateTime.now()} >>>>>> cereb websocket connecting......');
        },
        onDisconnect: (StompFrame stompFrame) {
          log('${DateTime.now()} >>>>>> cereb websocket disconnected......');
          isConnected = false;
          if (attempts < reconnectAttempts) {
            attempts++;
            Future.delayed(reconnectDelay, () {
              // Attempt to reconnect
              client?.activate();
            });
          }
        },
        onWebSocketError: (dynamic error) => log(error.toString()),
        stompConnectHeaders: {
          cerebWebsocketIdKey: cerebWebsocketId,
          cerebWebsocketPathKey: cerebWebsocketPath,
        },
      ),
    );
    return client;
  }
}

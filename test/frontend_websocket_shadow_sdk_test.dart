import 'dart:async';
import 'dart:developer';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_websocket_shadow_sdk/frontend_websocket_shadow_sdk.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

void main() {
  test('test websocket', () async {
    final completer = Completer<String>();
    const destination = '/user/topic/shadow_websocket';
    final client = CerebWebsocketShadowSdk(
      url: "https://dev-api.cereb.ai/v1/ws/shadow_websocket",
      path: "/user/topic/shadow_websocket",
      id: "A791716517900154M",
    );
    client.connect();
    client.subscribe(
      destination,
      (StompFrame frame) {
        log(frame.body ?? 'null');
        if (!completer.isCompleted) {
          completer.complete(frame.body);
        }
      },
    );

    final message = await completer.future;
    expect(message, isNotNull);

    client.send('test');
    client.unsubscribe(destination);
    client.disconnect();
  });
}

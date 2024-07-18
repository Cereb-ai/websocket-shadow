import 'dart:async';
import 'dart:developer';

import 'package:cereb_frontend_websocket_shadow_sdk/cereb_frontend_websocket_shadow_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

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

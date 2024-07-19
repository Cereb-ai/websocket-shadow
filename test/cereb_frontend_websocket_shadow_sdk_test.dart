import 'dart:async';
import 'dart:developer';

import 'package:cereb_frontend_websocket_shadow_sdk/cereb_frontend_websocket_shadow_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

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

    client.onConnect = (StompFrame frame) async {
      final response = await http.get(Uri.parse(
        'https://dev-workflow-webhook.cereb.ai/webhook/d1fe173d08e959397adf34b1d77e88d7/test',
      ));

      if (response.statusCode == 200) {
        final data = response.body;
        log(data);
      } else {
        throw Exception('Failed to load data');
      }
    };

    final message = await completer.future;
    expect(message, isNotNull);

    client.send('test');
    client.unsubscribe(destination);
    client.disconnect();
  });
}

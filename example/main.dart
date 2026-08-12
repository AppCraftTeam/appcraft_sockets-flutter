// ignore_for_file: avoid_print

import 'package:appcraft_sockets/appcraft_sockets.dart';

Future<void> main() async {
  final client = WebSocketClient(WebSocketClientOptions(
    serverUrl: 'wss://echo.websocket.events',
    onLog: print,
  ));

  // Handlers are matched in registration order, so the more specific type
  // goes first: JSON objects carrying an `info` field become an InfoMessage.
  client.registerJsonMessageType<InfoMessage>(
    (json) => json is Map && json.containsKey('info'),
    (json) => InfoMessage((json! as Map)['info'] as String),
  );

  // Anything the handler above did not claim is delivered as raw text.
  client.registerMessageType<AnyMessage>(
    (message) => true,
    (message) => AnyMessage(message.toString()),
  );

  client.listenMessages<InfoMessage>().listen(print);
  client.listenMessages<AnyMessage>().listen(print);

  // Called only when the client gives up: once all reconnection attempts have
  // been used up, or after disconnect().
  client.onSocketClose(() => print('Connection closed.'));

  await client.connect();

  client.sendJsonMessage({'info': 'hello'});

  await Future<void>.delayed(const Duration(seconds: 5));
  await client.dispose();
}

class InfoMessage {
  InfoMessage(this.info);

  final String info;

  @override
  String toString() => 'InfoMessage{info: $info}';
}

class AnyMessage {
  AnyMessage(this.msg);

  final String msg;

  @override
  String toString() => 'AnyMessage{msg: $msg}';
}

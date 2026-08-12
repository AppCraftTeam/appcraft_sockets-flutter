import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appcraft_sockets/appcraft_sockets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_server.dart';

class Message {
  Message(this.text);

  final String text;
}

class TextMessage extends Message {
  TextMessage(super.text);
}

class InfoMessage {
  InfoMessage(this.info);

  final String info;
}

void main() {
  late TestServer server;

  setUp(() async {
    server = await TestServer.start();
  });

  tearDown(() => server.stop());

  WebSocketClient createClient({
    String? url,
    int reconnectAttempts = 0,
    bool singleMessageTypeMatch = true,
    Duration reconnectInterval = const Duration(milliseconds: 20),
    WebSocketLogger? onLog,
  }) {
    final client = WebSocketClient(WebSocketClientOptions(
      serverUrl: url ?? server.url,
      reconnectAttempts: reconnectAttempts,
      reconnectInterval: reconnectInterval,
      singleMessageTypeMatch: singleMessageTypeMatch,
      onLog: onLog,
    ));
    addTearDown(client.dispose);
    return client;
  }

  /// Connects [client] and returns the server side of the connection.
  Future<WebSocket> connect(WebSocketClient client) async {
    final connection = server.nextConnection();
    await client.connect();
    return connection;
  }

  void registerPlainText(WebSocketClient client) =>
      client.registerMessageType<TextMessage>(
          (_) => true, (msg) => TextMessage(msg.toString()));

  group('connection', () {
    test('opens the connection', () async {
      final client = createClient();

      await connect(client);

      expect(client.isOpened, isTrue);
      expect(client.isClosed, isFalse);
      expect(server.connectionCount, 1);
    });

    test('throws once all connection attempts are used up', () async {
      final client = createClient(
        url: 'ws://127.0.0.1:${await TestServer.freePort()}',
        reconnectAttempts: 2,
        reconnectInterval: const Duration(milliseconds: 10),
      );

      await expectLater(client.connect(),
          throwsA(isA<WebSocketServerConnectionException>()));
    });

    test('reports the failure to every caller waiting on one attempt',
        () async {
      final client = createClient(
        url: 'ws://127.0.0.1:${await TestServer.freePort()}',
        reconnectAttempts: 2,
        reconnectInterval: const Duration(milliseconds: 10),
      );

      final first = client.connect();
      final second = client.connect();

      await expectLater(
          first, throwsA(isA<WebSocketServerConnectionException>()));
      await expectLater(
          second, throwsA(isA<WebSocketServerConnectionException>()));
      expect(server.connectionCount, 0);
    });

    test('completes a pending connect() when disconnected', () async {
      final client = createClient(
        url: 'ws://127.0.0.1:${await TestServer.freePort()}',
        reconnectInterval: const Duration(milliseconds: 20),
      );

      final pending = client.connect();
      await Future.delayed(const Duration(milliseconds: 50));

      await client.disconnect();

      // The caller is the one who gave up on the connection, so it is not
      // reported to them as a connection failure.
      await expectLater(pending, completes);
      expect(client.isOpened, isFalse);
    });
  });

  group('receiving', () {
    test('delivers plain messages as a typed stream', () async {
      final client = createClient();
      registerPlainText(client);
      final messages = client.listenMessages<TextMessage>();

      final socket = await connect(client);

      final received = messages.first;
      socket.add('hello');

      expect((await received).text, 'hello');
    });

    test('delivers decoded json messages and skips non-json ones', () async {
      final client = createClient();
      client.registerJsonMessageType<InfoMessage>(
          (json) => json is Map && json.containsKey('info'),
          (json) => InfoMessage((json! as Map)['info'] as String));
      final messages = client.listenMessages<InfoMessage>();

      final socket = await connect(client);

      final received = messages.first;
      socket.add('plain text, not json');
      socket.add('{"info":"ok"}');

      expect((await received).info, 'ok');
    });

    test('ignores binary frames', () async {
      final client = createClient();
      registerPlainText(client);
      final messages = client.listenMessages<TextMessage>();

      final socket = await connect(client);

      final received = messages.first;
      socket.add(<int>[1, 2, 3]);
      socket.add('text');

      expect((await received).text, 'text');
    });

    test('delivers a json null frame to json handlers', () async {
      final client = createClient();
      client.registerJsonMessageType<InfoMessage>(
          (json) => json == null, (_) => InfoMessage('null'));
      final messages = client.listenMessages<InfoMessage>();

      final socket = await connect(client);

      final received = messages.first;
      socket.add('null');

      expect((await received).info, 'null');
    });

    test('passes a message to the first matching handler by default', () async {
      final client = createClient();
      registerPlainText(client);
      client.registerMessageType<InfoMessage>(
          (_) => true, (msg) => InfoMessage(msg.toString()));

      final infos = <InfoMessage>[];
      client.listenMessages<InfoMessage>().listen(infos.add);
      final firstText = client.listenMessages<TextMessage>().first;

      final socket = await connect(client);
      socket.add('hello');
      await firstText;

      expect(infos, isEmpty);
    });

    test('passes a message to every matching handler when '
        'singleMessageTypeMatch is false', () async {
      final client = createClient(singleMessageTypeMatch: false);
      registerPlainText(client);
      client.registerMessageType<InfoMessage>(
          (_) => true, (msg) => InfoMessage(msg.toString()));

      final text = client.listenMessages<TextMessage>().first;
      final info = client.listenMessages<InfoMessage>().first;

      final socket = await connect(client);
      socket.add('hello');

      expect((await text).text, 'hello');
      expect((await info).info, 'hello');
    });
  });

  group('handler failures', () {
    test('reports a mapper failure on the stream of its own type', () async {
      final client = createClient(singleMessageTypeMatch: false);
      client.registerMessageType<TextMessage>(
          (_) => true, (_) => throw StateError('broken mapper'));
      client.registerMessageType<InfoMessage>(
          (_) => true, (msg) => InfoMessage(msg.toString()));

      final failure = client.listenMessages<TextMessage>().first;
      final info = client.listenMessages<InfoMessage>().first;

      final socket = await connect(client);
      socket.add('hello');

      await expectLater(failure, throwsA(isA<StateError>()));
      expect((await info).info, 'hello');
    });

    test('skips a handler whose predicate failed', () async {
      final client = createClient();
      client.registerMessageType<TextMessage>(
          (_) => throw StateError('broken predicate'),
          (msg) => TextMessage(msg.toString()));
      client.registerMessageType<InfoMessage>(
          (_) => true, (msg) => InfoMessage(msg.toString()));

      final info = client.listenMessages<InfoMessage>().first;

      final socket = await connect(client);
      socket.add('hello');

      expect((await info).info, 'hello');
    });

    test('survives a handler removal made from a message listener', () async {
      final client = createClient(singleMessageTypeMatch: false);
      registerPlainText(client);
      client.registerMessageType<InfoMessage>(
          (_) => true, (msg) => InfoMessage(msg.toString()));

      final info = client.listenMessages<InfoMessage>().first;
      client
          .listenMessages<TextMessage>()
          .listen((_) => client.removeMessageType<TextMessage>());

      final socket = await connect(client);
      socket.add('hello');

      expect((await info).info, 'hello');
    });
  });

  group('message types', () {
    test('listenMessages accepts a supertype of a registered type', () async {
      final client = createClient();
      registerPlainText(client);

      final messages = client.listenMessages<Message>();
      final socket = await connect(client);

      final received = messages.first;
      socket.add('hello');

      expect(await received, isA<TextMessage>());
    });

    test('listenMessages throws for an unregistered type', () {
      final client = createClient();
      registerPlainText(client);

      expect(() => client.listenMessages<InfoMessage>(),
          throwsA(isA<MissingMessageHandlerException<InfoMessage>>()));
    });

    test('removeMessageType removes both plain and json handlers', () async {
      final client = createClient();
      registerPlainText(client);
      client.registerJsonMessageType<TextMessage>(
          (_) => true, (msg) => TextMessage(msg.toString()));

      final closed = client.listenMessages<TextMessage>().isEmpty;
      client.removeMessageType<TextMessage>();

      await closed;
      expect(() => client.listenMessages<TextMessage>(),
          throwsA(isA<MissingMessageHandlerException<TextMessage>>()));
    });
  });

  group('sending', () {
    test('encodes the message and sends it to the server', () async {
      final client = createClient();
      await connect(client);

      final received = server.nextMessage();
      client.sendJsonMessage({'text': 'hi'});

      expect(jsonDecode(await received as String), {'text': 'hi'});
    });

    test('throws when the connection was never opened', () {
      final client = createClient();

      expect(() => client.sendJsonMessage({'text': 'hi'}),
          throwsA(isA<SocketClosedException>()));
    });

    test('throws when the connection is already closed', () async {
      final client = createClient();
      await connect(client);
      await client.disconnect();

      expect(() => client.sendJsonMessage({'text': 'hi'}),
          throwsA(isA<SocketClosedException>()));
    });
  });

  group('reconnection', () {
    test('reconnects when the server closes the connection normally', () async {
      final client = createClient();
      final socket = await connect(client);

      final reconnected = server.nextConnection();
      await socket.close(WebSocketStatus.normalClosure);
      await reconnected.timeout(const Duration(seconds: 5));

      await _waitUntil(() => client.isOpened);
      expect(server.connectionCount, 2);
      expect(client.isOpened, isTrue);
    });

    test('keeps message streams alive across a reconnect', () async {
      final client = createClient();
      registerPlainText(client);
      final messages = client.listenMessages<TextMessage>();

      final socket = await connect(client);

      final reconnected = server.nextConnection();
      await socket.close(WebSocketStatus.normalClosure);
      final newSocket = await reconnected.timeout(const Duration(seconds: 5));

      final received = messages.first;
      newSocket.add('after reconnect');

      expect((await received).text, 'after reconnect');
    });

    test('reconnects after the connection fails with an error', () async {
      final client = createClient();
      final socket = await connect(client);

      final reconnected = server.nextConnection();
      // Invalid UTF-8 in a text frame is a protocol error: the client's socket
      // reports it through onError rather than closing cleanly.
      socket.addUtf8Text([0xc3, 0x28]);
      await reconnected.timeout(const Duration(seconds: 10));

      await _waitUntil(() => client.isOpened);
      expect(client.isOpened, isTrue);
    });

    test('does not reconnect when disconnected while waiting to retry',
        () async {
      final client =
          createClient(reconnectInterval: const Duration(milliseconds: 500));
      final socket = await connect(client);

      // The connection drops and the client starts waiting out the interval.
      await socket.close(WebSocketStatus.normalClosure);
      await Future.delayed(const Duration(milliseconds: 50));

      await client.disconnect();

      // Long enough for the pending retry to have fired had it not been
      // cancelled. The server is still listening, so it would have succeeded.
      await Future.delayed(const Duration(seconds: 2));

      expect(client.isOpened, isFalse);
      expect(server.connectionCount, 1);
    });

    test('keeps no connection made after disconnect', () async {
      final port = await TestServer.freePort();
      final client = createClient(
        url: 'ws://127.0.0.1:$port',
        reconnectInterval: const Duration(milliseconds: 500),
      );

      // Nothing is listening yet, so the attempt is still pending.
      unawaited(client.connect());
      await Future.delayed(const Duration(milliseconds: 100));

      await client.disconnect();

      // A server appears exactly where the pending attempt is pointed. The
      // handshake may still complete, but the caller has already given up, so
      // the client must not end up holding the connection.
      final late = await TestServer.startOn(port);
      addTearDown(late.stop);
      await Future.delayed(const Duration(seconds: 2));

      expect(client.isOpened, isFalse);
      expect(late.openConnectionCount, 0);
    });

    test('drops frames that arrive after disconnect', () async {
      final client = createClient();
      registerPlainText(client);
      final received = <TextMessage>[];
      client.listenMessages<TextMessage>().listen(received.add);

      final socket = await connect(client);

      // The frame goes out before the close handshake completes, so it can
      // still reach the client's socket.
      final closing = client.disconnect();
      socket.add('after disconnect');
      await closing;
      await Future.delayed(const Duration(milliseconds: 100));

      expect(received, isEmpty);
    });

    test('does not reconnect after disconnect', () async {
      final client = createClient();
      final closed = Completer<void>();
      client.onSocketClose(() {
        if (!closed.isCompleted) closed.complete();
      });

      await connect(client);
      await client.disconnect();

      await closed.future.timeout(const Duration(seconds: 5));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(server.connectionCount, 1);
      expect(client.isOpened, isFalse);
    });

    test('notifies onSocketClose when reconnection fails', () async {
      final client = createClient(
        reconnectAttempts: 1,
        reconnectInterval: const Duration(milliseconds: 10),
      );
      final closed = Completer<void>();
      client.onSocketClose(() {
        if (!closed.isCompleted) closed.complete();
      });

      await connect(client);
      await server.stop();

      await closed.future.timeout(const Duration(seconds: 10));
      expect(client.isOpened, isFalse);
    });
  });

  group('logging', () {
    test('goes through dart:developer unless another logger is given', () {
      const options = WebSocketClientOptions(serverUrl: 'ws://127.0.0.1:1');

      expect(options.onLog, same(logToDeveloper));
    });

    test('reports the close code the peer sent', () async {
      final messages = <String>[];
      final client = createClient(onLog: messages.add);
      final socket = await connect(client);

      await socket.close(WebSocketStatus.normalClosure);
      await _waitUntil(
          () => messages.any((m) => m.startsWith('Websocket closed')));

      expect(messages, contains('Websocket connected.'));
      expect(messages, contains('Websocket closed. Reason code: 1000'));
    });
  });

  group('dispose', () {
    test('closes message streams and drops the handlers', () async {
      final client = createClient();
      registerPlainText(client);

      final closed = client.listenMessages<TextMessage>().isEmpty;
      await client.dispose();

      await closed;
      expect(() => client.listenMessages<TextMessage>(),
          throwsA(isA<MissingMessageHandlerException<TextMessage>>()));
    });
  });
}

Future<void> _waitUntil(bool Function() condition,
    {Duration timeout = const Duration(seconds: 5)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await Future.delayed(const Duration(milliseconds: 10));
  }
}

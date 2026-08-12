import 'dart:async';
import 'dart:io';

/// Local WebSocket server used by the client tests.
///
/// Keeps every accepted connection so that tests can drop them on purpose and
/// observe how the client reacts.
class TestServer {
  TestServer._(this._server) {
    _listen();
  }

  final HttpServer _server;
  final _connections = <WebSocket>[];
  final _connectionsController = StreamController<WebSocket>.broadcast();
  final _receivedController = StreamController<dynamic>.broadcast();
  var _stopped = false;

  static Future<TestServer> start() async =>
      TestServer._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  /// Starts on a specific port, to bring a server up where a client is already
  /// trying to connect.
  static Future<TestServer> startOn(int port) async =>
      TestServer._(await HttpServer.bind(InternetAddress.loopbackIPv4, port));

  /// A port nothing is listening on, useful to test failed connections.
  static Future<int> freePort() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    await server.close();
    return port;
  }

  String get url => 'ws://${_server.address.address}:${_server.port}';

  int get connectionCount => _connections.length;

  /// Connections the client has not closed yet.
  int get openConnectionCount =>
      _connections.where((s) => s.readyState == WebSocket.open).length;

  WebSocket get lastConnection => _connections.last;

  /// Completes with the next accepted connection. Must be called *before* the
  /// client is asked to connect.
  Future<WebSocket> nextConnection() => _connectionsController.stream.first;

  /// Completes with the next message sent by a client. Must be called *before*
  /// the message is sent.
  Future<dynamic> nextMessage() => _receivedController.stream.first;

  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;

    // The listening socket goes first, so nothing can be accepted while the
    // open connections are being torn down. Upgraded WebSockets are detached
    // from the HttpServer and have to be closed by hand even with force: true.
    await _server.close(force: true);
    for (final socket in List.of(_connections)) {
      await socket.close();
    }
    await _connectionsController.close();
    await _receivedController.close();
  }

  void _listen() {
    _server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      _connections.add(socket);
      if (!_connectionsController.isClosed) {
        _connectionsController.add(socket);
      }
      socket.listen(
        (data) {
          if (!_receivedController.isClosed) _receivedController.add(data);
        },
        onError: (_) {},
      );
    });
  }
}

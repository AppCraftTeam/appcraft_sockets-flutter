import 'dart:async';
import 'dart:convert';

import 'package:appcraft_sockets/core/exceptions.dart';
import 'package:appcraft_sockets/core/handler.dart';
import 'package:appcraft_sockets/models/options.dart';

import '../utils/mobile/websocket.dart'
    if (dart.library.js_interop) '../utils/web/websocket.dart';

/// A typed WebSocket client that keeps the connection alive until
/// [disconnect] or [dispose] is called.
///
/// The client knows nothing about the protocol: message types are registered
/// by the application through [registerMessageType] and
/// [registerJsonMessageType] and are consumed as typed streams via
/// [listenMessages].
class WebSocketClient {
  WebSocketClient(this._options);

  final WebSocketClientOptions _options;
  final _messageHandlers = <MessageHandler>[];

  void Function()? _onClosed;

  /// The socket of the live connection, non-null exactly between a successful
  /// connect and the close that ends it.
  ///
  /// Liveness is tracked here rather than read from `readyState`, because
  /// `dart:io` keeps reporting an open socket until the peer answers the close
  /// handshake — long after the connection has stopped carrying messages.
  WebSocketImpl? _socket;
  StreamSubscription? _subscription;

  /// The connection attempt in progress, shared by everyone who asks for a
  /// connection while it runs.
  Future<void>? _connectionAttempt;

  var _shouldConnect = false;

  /// Whether a connection is open right now.
  bool get isOpened => _socket != null;

  /// Whether a connection attempt is running, including the ones started by
  /// automatic reconnection.
  bool get isConnecting => _connectionAttempt != null;

  /// Whether there is neither an open connection nor a running attempt.
  ///
  /// This is also true while the client waits out
  /// [WebSocketClientOptions.reconnectInterval] between two attempts, so it
  /// does not mean the client has stopped trying: giving up is reported
  /// through the callback registered with [onSocketClose].
  bool get isClosed => _socket == null && _connectionAttempt == null;

  /// Connects to [WebSocketClientOptions.serverUrl].
  ///
  /// When a connection attempt is already running this joins it instead of
  /// starting a second one, so the returned future reports the outcome of that
  /// attempt rather than completing straight away.
  ///
  /// Throws [WebSocketServerConnectionException] when the connection could not
  /// be established within [WebSocketClientOptions.reconnectAttempts] attempts.
  Future<void> connect() {
    if (isOpened) {
      return Future.value();
    }
    _shouldConnect = true;

    return _openSocket();
  }

  Future<void> _openSocket() =>
      _connectionAttempt ??= _connectAndListen().whenComplete(() {
        _connectionAttempt = null;
      });

  Future<void> _connectAndListen() async {
    if (isOpened) {
      return;
    }

    await _subscription?.cancel();
    _subscription = null;

    final WebSocketImpl socket;
    try {
      socket = await _connectWs(_options.serverUrl);
    } on WebSocketServerConnectionException {
      // The attempt ended because disconnect() or dispose() gave up on it, not
      // because the server could not be reached. Whoever awaits connect() has
      // asked for the connection to be dropped and is not told it failed.
      if (!_shouldConnect) {
        return;
      }
      rethrow;
    }

    // disconnect() or dispose() may have been called while the connection was
    // being established: nothing may be left running behind their back.
    if (!_shouldConnect) {
      await socket.close();
      return;
    }

    _socket = socket;
    _subscription = socket.listen(
      _handleSocketMessage,
      onError: _handleSocketError,
      onDone: () => _handleSocketDone(socket),
    );
  }

  Future<WebSocketImpl> _connectWs(String url) async {
    var attemptNumber = 0;

    while (true) {
      attemptNumber++;

      _log('Connecting to websocket (attempt $attemptNumber)...');

      try {
        final socket = WebSocketImpl();
        await socket.connect(url);

        _log('Websocket connected.');

        return socket;
      } on Exception catch (exception) {
        _log('Websocket connection failed: $exception');

        final hasAttemptsLeft = _options.reconnectAttempts == 0 ||
            attemptNumber < _options.reconnectAttempts;

        if (!_shouldConnect || !hasAttemptsLeft) {
          throw WebSocketServerConnectionException(exception.toString());
        }

        await Future.delayed(_options.reconnectInterval);

        // The caller may have given up during the pause.
        if (!_shouldConnect) {
          throw WebSocketServerConnectionException(exception.toString());
        }
      }
    }
  }

  /// Called for every closed connection, no matter which close code the peer
  /// reported. As long as [disconnect] has not been called the connection is
  /// considered lost and is re-established.
  void _handleSocketDone(WebSocketImpl socket) {
    _socket = null;

    _log('Websocket closed. Reason code: ${socket.closeCode}');

    if (!_shouldConnect) {
      _onClosed?.call();
      return;
    }

    unawaited(_reconnect());
  }

  /// Connection errors are always followed by a close event, so reconnection
  /// is driven by [_handleSocketDone] alone.
  void _handleSocketError(Object error) {
    if (_socket == null) {
      return;
    }

    _log('Websocket error: $error');
  }

  /// Waits out [WebSocketClientOptions.reconnectInterval] before reconnecting.
  /// A server that accepts a connection and drops it right away would
  /// otherwise be hammered at connection-setup rate.
  Future<void> _reconnect() async {
    try {
      await Future.delayed(_options.reconnectInterval);

      if (!_shouldConnect || isOpened || isConnecting) {
        return;
      }

      await _openSocket();
    } catch (error) {
      _log('Websocket reconnection failed: $error');

      // There is no caller left to throw at, so giving up is reported through
      // the callback instead.
      if (_shouldConnect) {
        _shouldConnect = false;
        _onClosed?.call();
      }
    }
  }

  void _handleSocketMessage(dynamic msg) {
    // Frames that arrive between the local close and the peer's answer to the
    // close handshake belong to a connection whose owner has already been told
    // it is gone, so they are not delivered.
    if (_socket == null) {
      return;
    }

    // Binary frames are out of scope: the platform sockets deliver them as
    // something other than a String, and handlers are defined over text.
    if (msg is! String) {
      _log('Ignored a non-text frame of type ${msg.runtimeType}.');
      return;
    }

    Object? json;
    var isJson = false;
    try {
      json = jsonDecode(msg);
      isJson = true;
    } catch (_) {
      // Not JSON: the frame is offered to the plain handlers only. Decoding
      // success is tracked separately because `null` is valid JSON too.
    }

    var handlerMatched = false;

    for (final handler in _messageHandlers) {
      final isJsonHandler = handler is JsonMessageHandler;
      if (isJsonHandler && !isJson) {
        continue;
      }

      final arg = isJsonHandler ? json : msg;

      final bool matches;
      try {
        matches = handler.predicate(arg);
      } catch (error) {
        // A predicate that could not tell whether the frame is its own does
        // not claim it: the remaining handlers still get their chance at it.
        _reportHandlerError(handler, error);
        continue;
      }

      if (!matches) {
        continue;
      }

      handlerMatched = true;

      try {
        handler.streamController.add(handler.mapper(arg));
      } catch (error) {
        // The frame was recognised, so it stays claimed by this handler even
        // though no model could be built out of it.
        _reportHandlerError(handler, error);
      }

      if (_options.singleMessageTypeMatch) return;
    }

    if (!handlerMatched && _options.onLog != null) {
      // Only the beginning of the frame is logged: a whole payload in the log
      // is both noise and a way to spill user data into it.
      final preview = msg.length <= 120
          ? msg
          : '${msg.substring(0, 120)}... (${msg.length} characters)';

      _log('No handler matched message: $preview');
    }
  }

  void _log(String message) => _options.onLog?.call(message);

  /// Reports a failure of an application-supplied predicate or mapper on the
  /// stream of the type they were registered for, so that it surfaces where
  /// the messages of that type are consumed rather than as an unhandled error
  /// of the socket subscription.
  void _reportHandlerError(MessageHandler handler, Object error) {
    _log('Message handler failed: $error');

    handler.streamController.addError(error);
  }

  /// Closes the connection and stops reconnecting.
  Future<void> disconnect() async {
    _shouldConnect = false;

    final socket = _socket;
    _socket = null;

    // The subscription is left in place on purpose: the close event it still
    // delivers is what invokes the callback given to [onSocketClose].
    if (socket != null) {
      await socket.close();
    }
  }

  /// Registers [onClosed] to be called when the connection is closed and the
  /// client is not going to restore it, either because [disconnect] was called
  /// or because all reconnection attempts have been used up.
  ///
  /// One callback is kept at a time: a later call replaces the one registered
  /// before it.
  void onSocketClose(void Function() onClosed) {
    _onClosed = onClosed;
  }

  /// Registers a handler for messages of type [T].
  /// Passes received message as is in [predicate] and [mapper] functions.
  void registerMessageType<T>(WebSocketMessageTypePredicate predicate,
      WebSocketMessageMapper<T, dynamic> mapper) {
    final handler = PlainMessageHandler<T>(
        predicate, mapper, StreamController<T>.broadcast());
    _messageHandlers.add(handler);
  }

  /// Registers a handler for messages of type [T].
  /// Passes received message as parsed JSON-object in [predicate] and [mapper] functions.
  /// Messages that can't be parsed into JSON will be ignored.
  void registerJsonMessageType<T>(
      WebSocketMessageTypePredicate<Object> predicate,
      WebSocketMessageMapper<T, Object> mapper) {
    final handler = JsonMessageHandler<T>(
        predicate, mapper, StreamController<T>.broadcast());
    _messageHandlers.add(handler);
  }

  /// Removes every handler that produces messages of type [T], both the plain
  /// and the JSON ones, and closes the streams returned for them by
  /// [listenMessages].
  ///
  /// Subtypes are matched the same way [listenMessages] matches them, so
  /// removing a base type removes the handlers of its subtypes as well:
  /// `removeMessageType<Object>()` drops every registered handler.
  void removeMessageType<T>() {
    _messageHandlers.removeWhere((handler) {
      if (!handler.canHandle<T>()) {
        return false;
      }
      unawaited(handler.streamController.close());
      return true;
    });
  }

  /// Listen messages of type [T] according to handlers addition order.
  /// If multiple registered types can match one message, then
  /// ensure that parameter [WebSocketClientOptions.singleMessageTypeMatch] is false.
  Stream<T> listenMessages<T>() {
    for (final handler in _messageHandlers) {
      if (handler.canHandle<T>()) {
        return handler.streamController.stream as Stream<T>;
      }
    }

    throw MissingMessageHandlerException<T>();
  }

  /// Codes [message] to JSON format and sends it to a server.
  /// Note, that type of [message] should be compatible with jsonEncode() function (dart:convert).
  /// Otherwise, your type should contains toJson() method and annotation JsonSerializable().
  ///
  /// Throws [SocketClosedException] when the connection is not open.
  void sendJsonMessage(dynamic message) {
    if (!isOpened) {
      throw SocketClosedException();
    }
    _socket!.add(jsonEncode(message));
  }

  /// Disconnects, drops every registered message type and closes the streams
  /// handed out by [listenMessages]. The callback given to [onSocketClose] is
  /// dropped as well.
  ///
  /// The client stays usable afterwards: registering the message types again
  /// and calling [connect] starts a fresh connection.
  Future<void> dispose() async {
    await disconnect();

    await _subscription?.cancel();
    _subscription = null;
    _onClosed = null;

    for (final h in _messageHandlers) {
      await h.streamController.close();
    }
    _messageHandlers.clear();
  }
}

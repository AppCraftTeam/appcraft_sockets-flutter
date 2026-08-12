import 'package:appcraft_sockets/core/logging.dart';

/// Immutable configuration of a `WebSocketClient`.
class WebSocketClientOptions {
  const WebSocketClientOptions(
      {required this.serverUrl,
      this.reconnectAttempts = 0,
      this.onLog = logToDeveloper,
      this.singleMessageTypeMatch = true,
      this.reconnectInterval = const Duration(seconds: 2)});

  /// Number of connection attempts made for the initial connection and
  /// for each subsequent connection loss.
  /// 0 (default) - infinite
  /// With 0 the future returned by connect() completes only once the
  /// connection is established or disconnect() is called.
  final int reconnectAttempts;

  /// Delay between two connection attempts.
  /// It is also waited out before the first attempt made after a connection
  /// is lost.
  final Duration reconnectInterval;

  /// Called with connection lifecycle messages and handler failures, each of
  /// them a single line already carrying the error it reports, if any.
  /// Defaults to [logToDeveloper]; set it to null to log nothing, or to any
  /// other function to route the messages where the application wants them.
  final WebSocketLogger? onLog;

  /// WebSocket URL the client connects to.
  final String serverUrl;

  /// Determines whether to pass received message to
  /// all matched types or to first matched only.
  /// Defaults to true.
  final bool singleMessageTypeMatch;
}

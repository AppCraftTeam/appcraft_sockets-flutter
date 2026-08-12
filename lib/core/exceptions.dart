/// Thrown when the connection to the server could not be established within
/// the configured number of attempts.
class WebSocketServerConnectionException implements Exception {
  final String? _msg;

  WebSocketServerConnectionException([this._msg]);

  @override
  String toString() {
    return _msg ?? 'Unknown server connection error';
  }
}

/// Thrown when a message is sent over a connection that is not open.
class SocketClosedException implements Exception {
  @override
  String toString() {
    return 'The socket is not open. Call connect() before sending messages.';
  }
}

/// Thrown when messages of type [T] are requested but no handler producing
/// them has been registered.
class MissingMessageHandlerException<T> implements Exception {
  MissingMessageHandlerException()
      : _msg = 'No message handler registered for type $T';
  final String _msg;

  @override
  String toString() {
    return _msg;
  }
}

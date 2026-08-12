import 'dart:developer' as developer;

/// Receives the connection lifecycle messages of a `WebSocketClient`.
typedef WebSocketLogger = void Function(String message);

/// A [WebSocketLogger] that hands the messages to `dart:developer`, tagged
/// with the name of the package: in a Flutter app they reach the debug console
/// and the DevTools logging view, where they can be filtered by that name,
/// instead of going to standard output.
///
/// A plain Dart process with no VM service attached drops them, so a console
/// program is better served by `onLog: print`.
void logToDeveloper(String message) =>
    developer.log(message, name: 'appcraft_sockets');

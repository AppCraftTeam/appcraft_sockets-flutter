import 'dart:async';
import 'dart:js_interop';

import 'package:appcraft_sockets/core/exceptions.dart';
import 'package:web/web.dart' as web;

class WebSocketImpl {
  late web.WebSocket _socket;

  int? _closeCode;

  int? get closeCode => _closeCode;

  /// Completes when the browser reports the connection as open and
  /// fails with [WebSocketServerConnectionException] if it could not be
  /// established. The `WebSocket` constructor itself never reports failures.
  Future<void> connect(String url) {
    final socket = web.WebSocket(url);
    _socket = socket;

    final completer = Completer<void>();

    final onOpen = ((web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }).toJS;

    final onError = ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(
            WebSocketServerConnectionException('Failed to connect to $url'));
      }
    }).toJS;

    socket.addEventListener('open', onOpen);
    socket.addEventListener('error', onError);

    return completer.future.whenComplete(() {
      socket.removeEventListener('open', onOpen);
      socket.removeEventListener('error', onError);
    });
  }

  void add(String data) => _socket.send(data.toJS);

  Future<void> close() async => _socket.close();

  /// Browsers expose messages, errors and the close event as three separate
  /// event streams, so they are merged into a single stream here to give the
  /// same `onData` / `onError` / `onDone` contract as the `dart:io` socket.
  StreamSubscription listen(void Function(dynamic event) onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    final controller = StreamController<dynamic>();

    final onMessageListener = ((web.MessageEvent event) {
      controller.add(event.data.dartify());
    }).toJS;

    final onErrorListener = ((web.Event _) {
      if (!controller.isClosed) {
        controller.addError(WebSocketServerConnectionException(
            'Websocket connection error'));
      }
    }).toJS;

    final onCloseListener = ((web.CloseEvent event) {
      _closeCode = event.code;
      if (!controller.isClosed) controller.close();
    }).toJS;

    _socket.addEventListener('message', onMessageListener);
    _socket.addEventListener('error', onErrorListener);
    _socket.addEventListener('close', onCloseListener);

    controller.onCancel = () {
      _socket.removeEventListener('message', onMessageListener);
      _socket.removeEventListener('error', onErrorListener);
      _socket.removeEventListener('close', onCloseListener);
    };

    return controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

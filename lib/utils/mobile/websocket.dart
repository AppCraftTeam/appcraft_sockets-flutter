import 'dart:async';
import 'dart:io';

class WebSocketImpl {
  late WebSocket _socket;

  int? get closeCode => _socket.closeCode;

  Future<void> connect(String url) async {
    _socket = await WebSocket.connect(url);
  }

  void add(String data) => _socket.add(data);

  Future<void> close() => _socket.close();

  StreamSubscription listen(void Function(dynamic event) onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _socket.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
}

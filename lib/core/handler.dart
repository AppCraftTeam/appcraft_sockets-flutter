import 'dart:async';

/// Recognises whether an incoming [message] belongs to a registered type.
typedef WebSocketMessageTypePredicate<M> = bool Function(M? message);

/// Builds an application model of type [T] out of an incoming [message].
typedef WebSocketMessageMapper<T, M> = T Function(M? message);

abstract class MessageHandler<T, R> {
  MessageHandler(this.predicate, this.mapper, this.streamController);

  final WebSocketMessageTypePredicate<R> predicate;
  final WebSocketMessageMapper<T, R> mapper;
  final StreamController<T> streamController;

  /// Whether messages produced by this handler can be consumed as [M],
  /// i.e. whether [T] is [M] itself or a subtype of it.
  bool canHandle<M>() => <T>[] is List<M>;
}

class PlainMessageHandler<T> extends MessageHandler<T, dynamic> {
  PlainMessageHandler(super.predicate, super.mapper, super.streamController);
}

class JsonMessageHandler<T> extends MessageHandler<T, Object> {
  JsonMessageHandler(super.predicate, super.mapper, super.streamController);
}

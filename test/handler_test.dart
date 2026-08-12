import 'dart:async';

import 'package:appcraft_sockets/core/handler.dart';
import 'package:flutter_test/flutter_test.dart';

class Message {}

class TextMessage extends Message {}

void main() {
  group('MessageHandler.canHandle', () {
    late PlainMessageHandler<TextMessage> handler;

    setUp(() {
      handler = PlainMessageHandler<TextMessage>((_) => true,
          (_) => TextMessage(), StreamController<TextMessage>.broadcast());
    });

    tearDown(() => handler.streamController.close());

    test('matches the exact type', () {
      expect(handler.canHandle<TextMessage>(), isTrue);
    });

    test('matches a supertype', () {
      expect(handler.canHandle<Message>(), isTrue);
    });

    test('does not match a subtype', () {
      final baseHandler = PlainMessageHandler<Message>(
          (_) => true, (_) => Message(), StreamController<Message>.broadcast());
      addTearDown(baseHandler.streamController.close);

      expect(baseHandler.canHandle<TextMessage>(), isFalse);
    });

    test('does not match an unrelated type', () {
      expect(handler.canHandle<String>(), isFalse);
    });
  });
}

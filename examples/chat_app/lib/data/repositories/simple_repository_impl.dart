import 'dart:convert';

import 'package:appcraft_sockets/appcraft_sockets.dart';
import 'package:example/data/datasource/simple_datasource.dart';
import 'package:example/domain/entities/simple_message.dart';
import 'package:example/domain/entities/user_entity.dart';
import 'package:example/domain/repositories/simple_repository.dart';

class SimpleRepositoryImpl implements SimpleRepository {
  final SimpleDataSource dataSource;
  final WebSocketClient _client;
  var _init = false;

  SimpleRepositoryImpl(this._client, this.dataSource);

  @override
  Future<UserEntity?> getCurrentUser() async => await dataSource.getCurrentUser();

  @override
  Future<bool> isSignIn() async => await dataSource.isSignIn();

  @override
  Future<void> signIn(String login) async => await dataSource.signIn(login);

  @override
  Stream<SimpleMessage> getMessages() {
    return _client.listenMessages<SimpleMessage>();
  }

  @override
  Future<void> sendTextMessage(SimpleMessage textMessage) {
    _client.sendJsonMessage(textMessage);
    return Future.value();
  }

  @override
  Future<void> signOut() async {
    await _client.dispose();
    await dataSource.signOut();
    _init = false;
  }

  @override
  Future<void> connectSocket() async {
    if (!_init) {
      // Так написано только из-за того, что сообщения идут с общедоступного вебсокета для теста,
      // для того, чтобы отображать все сообщения, а не только нужного нам формата.
      const _msgKeys = ['senderId', 'message'];
      _client.registerMessageType<SimpleMessage>((msg) => true, (msg) {
        try {
          final json = jsonDecode(msg) as Map<String, dynamic>;
          if (!_msgKeys.every(json.containsKey)) {
            throw Error();
          }

          return SimpleMessage.fromJson(json);
        } catch (_) {
          return SimpleMessage('unknown', 'Anonymous', 'TEXT', DateTime.now(), msg.toString());
        }
      });

      // Нормальная реализация для json-сообщений

      // _client.registerJsonMessageType<SimpleMessage>(
      //     (msg) => msg is Map<String, dynamic> && _msgKeys.every(msg.containsKey),
      //     (msg) => SimpleMessage.fromJson(msg as Map<String, dynamic>));
      _init = true;
    }
    await _client.connect();
  }
}

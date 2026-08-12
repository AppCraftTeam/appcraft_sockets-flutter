import 'package:example/domain/entities/simple_message.dart';
import 'package:example/domain/entities/user_entity.dart';

abstract class SimpleRepository {
  Future<void> signIn(String login);

  Future<bool> isSignIn();

  Future<void> signOut();

  Future<UserEntity?> getCurrentUser();

  Future<void> sendTextMessage(SimpleMessage textMessage);

  Stream<SimpleMessage> getMessages();

  Future<void> connectSocket();
}

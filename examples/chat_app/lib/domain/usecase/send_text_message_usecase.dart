import 'package:example/domain/entities/simple_message.dart';
import 'package:example/domain/repositories/simple_repository.dart';

class SendTextMessageUseCase {
  final SimpleRepository repository;

  SendTextMessageUseCase({required this.repository});

  Future<void> call(SimpleMessage textMessage) {
    return repository.sendTextMessage(textMessage);
  }
}

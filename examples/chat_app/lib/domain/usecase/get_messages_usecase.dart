import 'package:example/domain/entities/simple_message.dart';
import 'package:example/domain/repositories/simple_repository.dart';

class GetMessagesUseCase {
  final SimpleRepository repository;

  GetMessagesUseCase({required this.repository});

  Stream<SimpleMessage> call() => repository.getMessages();
}

import 'package:example/domain/repositories/simple_repository.dart';

class SignInUseCase {
  final SimpleRepository repository;

  SignInUseCase({required this.repository});

  Future<void> call(String login) {
    return repository.signIn(login);
  }
}

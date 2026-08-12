import 'package:example/domain/repositories/simple_repository.dart';

class SignOutUseCase {
  final SimpleRepository repository;

  SignOutUseCase({required this.repository});

  Future<void> call() async {
    return await repository.signOut();
  }
}

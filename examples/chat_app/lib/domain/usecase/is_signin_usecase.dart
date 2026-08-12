import 'package:example/domain/repositories/simple_repository.dart';

class IsSignInUseCase {
  final SimpleRepository repository;

  IsSignInUseCase(this.repository);

  Future<bool> call() async => repository.isSignIn();
}

import 'package:example/domain/entities/user_entity.dart';
import 'package:example/domain/repositories/simple_repository.dart';

class GetCurrentUserUseCase {
  final SimpleRepository repository;

  GetCurrentUserUseCase({required this.repository});

  Future<UserEntity?> call() async => await repository.getCurrentUser();
}

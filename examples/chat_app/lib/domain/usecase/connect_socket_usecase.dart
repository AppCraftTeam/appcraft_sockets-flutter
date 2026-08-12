import 'package:example/domain/repositories/simple_repository.dart';

class ConnectSocketUseCase {
  ConnectSocketUseCase(this._repository);

  final SimpleRepository _repository;

  Future<void> call() => _repository.connectSocket();
}

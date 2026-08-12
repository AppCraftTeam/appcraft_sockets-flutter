import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String? name;
  final String? uid;

  const UserEntity(this.name, this.uid);

  @override
  List<Object?> get props => [name, uid];
}

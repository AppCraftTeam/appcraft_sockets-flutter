import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:example/domain/usecase/connect_socket_usecase.dart';
import 'package:example/domain/usecase/get_current_user_usecase.dart';
import 'package:example/domain/usecase/is_signin_usecase.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final IsSignInUseCase isSignInUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final ConnectSocketUseCase connectSocketUseCase;

  AuthCubit(
      {required this.isSignInUseCase,
      required this.getCurrentUserUseCase,
      required this.connectSocketUseCase})
      : super(AuthInitial());

  Future<void> appStarted() async {
    try {
      final isSignIn = await isSignInUseCase();
      if (isSignIn == true) {
        final user = await getCurrentUserUseCase();
        await connectSocketUseCase();
        emit(Authenticated(uid: user!.uid!, username: user.name!));
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> loggedIn() async {
    final user = await getCurrentUserUseCase();
    await connectSocketUseCase();
    emit(Authenticated(uid: user!.uid!, username: user.name!));
  }

  Future<void> loggedOut() async {
    emit(Unauthenticated());
  }
}

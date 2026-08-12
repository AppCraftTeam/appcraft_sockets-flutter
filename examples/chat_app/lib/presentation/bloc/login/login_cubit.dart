import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:example/domain/usecase/sign_out_usecase.dart';
import 'package:example/domain/usecase/signin_usecase.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final SignInUseCase signInUseCase;
  final SignOutUseCase signOutUseCase;

  LoginCubit({required this.signInUseCase, required this.signOutUseCase}) : super(LoginInitial());

  Future<void> submitLogin({required String login}) async {
    emit(LoginLoading());
    try {
      await signInUseCase(login);
      emit(LoginSuccess());
    } on SocketException catch (e) {
      emit(LoginFailure(e.message));
    } catch (_) {
      emit(const LoginFailure("firebase exception"));
    }
  }

  Future<void> submitSignOut() async {
    try {
      await signOutUseCase();
    } on SocketException catch (_) {}
  }
}

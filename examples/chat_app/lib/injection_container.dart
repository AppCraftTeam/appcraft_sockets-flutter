import 'package:appcraft_sockets/appcraft_sockets.dart';
import 'package:example/data/datasource/simple_datasource.dart';
import 'package:example/data/repositories/simple_repository_impl.dart';
import 'package:example/domain/repositories/simple_repository.dart';
import 'package:example/domain/usecase/connect_socket_usecase.dart';
import 'package:example/domain/usecase/get_current_user_usecase.dart';
import 'package:example/domain/usecase/get_messages_usecase.dart';
import 'package:example/domain/usecase/is_signin_usecase.dart';
import 'package:example/domain/usecase/send_text_message_usecase.dart';
import 'package:example/domain/usecase/sign_out_usecase.dart';
import 'package:example/domain/usecase/signin_usecase.dart';
import 'package:example/presentation/bloc/auth/auth_cubit.dart';
import 'package:example/presentation/bloc/communication/communication_cubit.dart';
import 'package:example/presentation/bloc/login/login_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;
const url =
    'wss://demo.piesocket.com/v3/channel_1?api_key=oCdCMcMPQpbvNjUIzqtvF1d2X2okWpDQj4AwARJuAgtjhzKxVEjQU6IdCjwm&notify_self';

Future<void> init() async {
  //Features bloc,
  getIt.registerSingletonAsync<AuthCubit>(() async => AuthCubit(
      isSignInUseCase: await getIt.getAsync(),
      getCurrentUserUseCase: getIt(),
      connectSocketUseCase: getIt()));
  getIt.registerLazySingleton<LoginCubit>(() => LoginCubit(
        signInUseCase: getIt(),
        signOutUseCase: getIt(),
      ));
  getIt.registerLazySingleton<WebSocketClient>(
      () => WebSocketClient(const WebSocketClientOptions(serverUrl: url)));
  getIt.registerLazySingleton<CommunicationCubit>(
      () => CommunicationCubit(getMessagesUseCase: getIt(), sendTextMessageUseCase: getIt()));
  //!useCase
  getIt.registerLazySingleton<ConnectSocketUseCase>(() => ConnectSocketUseCase(getIt()));
  getIt
      .registerSingletonAsync<IsSignInUseCase>(() async => IsSignInUseCase(await getIt.getAsync()));
  getIt.registerLazySingleton<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(repository: getIt()));
  getIt.registerLazySingleton<SignInUseCase>(() => SignInUseCase(repository: getIt()));
  getIt.registerLazySingleton<GetMessagesUseCase>(() => GetMessagesUseCase(repository: getIt()));
  getIt.registerLazySingleton<SendTextMessageUseCase>(
      () => SendTextMessageUseCase(repository: getIt()));
  getIt.registerLazySingleton<SignOutUseCase>(() => SignOutUseCase(repository: getIt()));

  getIt.registerSingletonAsync<SharedPreferences>(() => SharedPreferences.getInstance());
  //repository
  getIt.registerSingletonAsync<SimpleRepository>(
      () async => SimpleRepositoryImpl(getIt(), await getIt.getAsync()));
  //dataSource
  getIt.registerSingletonAsync<SimpleDataSource>(
      () async => SimpleDataSourceImpl(await getIt.getAsync()));
  //external
  //e.g final sharedPreference=await SharedPreferences.getInstance();
  await getIt.allReady();
}

import 'package:example/presentation/bloc/auth/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'injection_container.dart' as di;
import 'presentation/bloc/communication/communication_cubit.dart';
import 'presentation/bloc/login/login_cubit.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  di.getIt<AuthCubit>().appStarted();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(
          value: di.getIt<AuthCubit>(),
        ),
        BlocProvider<LoginCubit>.value(
          value: di.getIt<LoginCubit>(),
        ),
        BlocProvider<CommunicationCubit>.value(
          value: di.getIt<CommunicationCubit>(),
        )
      ],
      child: MaterialApp(
        title: 'Flutter Group Chat Room',
        debugShowCheckedModeBanner: false,
        routes: {
          "/": (context) {
            return BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (authState is Authenticated) {
                  return WelcomeScreen(uid: authState.uid, username: authState.username);
                }
                if (authState is Unauthenticated) {
                  return const HomeScreen();
                }
                return Container();
              },
            );
          }
        },
      ),
    );
  }
}

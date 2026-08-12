import 'package:example/presentation/bloc/auth/auth_cubit.dart';
import 'package:example/presentation/bloc/login/login_cubit.dart';
import 'package:example/presentation/screens/single_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

class WelcomePageWeb extends StatefulWidget {
  final String uid;
  final String username;

  const WelcomePageWeb({Key? key, required this.uid, required this.username}) : super(key: key);

  @override
  _WelcomePageWebState createState() => _WelcomePageWebState();
}

class _WelcomePageWebState extends State<WelcomePageWeb> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
              colors: [
                Colors.indigo[400]!,
                Colors.blue[300]!,
              ],
            )),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Lottie.asset(
              "assets/congratulation.json",
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Lottie.asset("assets/bubble.json"),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
                margin: const EdgeInsets.only(top: 150),
                child: Text(
                  "Welcome ${widget.username}",
                  style: const TextStyle(
                    fontSize: 30,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )),
          ),
          _joinGlobalChatButton(name: widget.username),
          _logOutWidget(),
        ],
      ),
    );
  }

  Widget _joinGlobalChatButton({required String name}) {
    return Align(
      alignment: Alignment.center,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Join Us For Fun",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SingleChatScreen(
                      username: name,
                      uid: widget.uid,
                    ),
                  ),
                );
              },
              child: Container(
                width: 250,
                height: 70,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.3),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    border: Border.all(color: Colors.white60, width: 2)),
                child: const Text(
                  "Join",
                  style: TextStyle(fontSize: 30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logOutWidget() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: InkWell(
        onTap: () {
          BlocProvider.of<AuthCubit>(context).loggedOut();
          BlocProvider.of<LoginCubit>(context).submitSignOut();
        },
        child: Container(
          margin: const EdgeInsets.only(left: 15, bottom: 15),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.3),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(
            Icons.exit_to_app,
            size: 30,
          ),
        ),
      ),
    );
  }
}

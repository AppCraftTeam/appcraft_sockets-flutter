import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:responsive_builder/responsive_builder.dart';

class LeftSideWidget extends StatelessWidget {
  final SizingInformation sizingInformation;

  const LeftSideWidget({Key? key, required this.sizingInformation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: sizingInformation.screenSize.width * 0.55,
      height: double.infinity,
      decoration: BoxDecoration(
          gradient: LinearGradient(
        colors: [
          Colors.indigo[400]!,
          Colors.blue[300]!,
        ],
      )),
      child: Stack(
        children: [
          _loginButton(),
          _bgImageWidget(),
          _welcomeTextWidget(),
          Positioned(
              left: -150,
              bottom: -150,
              child: Image.asset(
                "assets/shape.png",
                color: Colors.white.withOpacity(.2),
              ))
        ],
      ),
    );
  }

  Widget _loginButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            border: Border.all(color: Colors.white60, width: 1.50),
          ),
          child: const Text(
            "LOGIN",
            style: TextStyle(fontSize: 16, color: Colors.white60),
          )),
    );
  }

  _bgImageWidget() {
    return Align(
      alignment: Alignment.center,
      child: Lottie.asset("assets/img.json"),
    );
  }

  Widget _welcomeTextWidget() {
    return Positioned(
      left: 35,
      bottom: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: sizingInformation.screenSize.width * 0.45,
            child: const Text(
              "WELCOME TO eTechViral",
              style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          SizedBox(
            width: sizingInformation.screenSize.width * 0.45,
            child: const Text(
              "Flutter is changing the app development world. if you want to improve your flutter skill then join our channel because we try to upload one video per week. eTechViral :- flutter and dart app development tutorials crafted to make you win jobs.",
              textAlign: TextAlign.start,
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(15)),
                border: Border.all(color: Colors.white60, width: 1.50),
              ),
              child: const Text(
                "SIGN IN",
                style: TextStyle(fontSize: 16, color: Colors.white60),
              )),
        ],
      ),
    );
  }
}

import 'package:example/presentation/pages/mobile/welcome_page_mobile.dart';
import 'package:example/presentation/pages/tablet/welcome_page_tablet.dart';
import 'package:example/presentation/pages/web/welcome_page_web.dart';
import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

class WelcomeScreen extends StatelessWidget {
  final String uid;
  final String username;

  const WelcomeScreen({Key? key, required this.uid, required this.username}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        if (sizingInformation.isDesktop) {
          return WelcomePageWeb(uid: uid, username: username);
        }
        if (sizingInformation.isTablet) {
          return WelcomePageTablet(uid: uid, username: username);
        }
        return WelcomePageMobile(uid: uid, username: username);
      },
    );
  }
}

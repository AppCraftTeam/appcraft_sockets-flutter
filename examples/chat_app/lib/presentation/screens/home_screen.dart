import 'package:example/presentation/pages/mobile/mobile_page.dart';
import 'package:example/presentation/pages/tablet/tablet_page.dart';
import 'package:example/presentation/pages/web/web_page.dart';
import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        if (sizingInformation.isDesktop) {
          return WebPage(sizingInformation: sizingInformation);
        }
        if (sizingInformation.isTablet) {
          return const TabletPage();
        }
        return const MobilePage();
      },
    );
  }
}

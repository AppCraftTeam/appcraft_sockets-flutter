import 'package:example/presentation/pages/tablet/widgets/left_side_widget.dart';
import 'package:example/presentation/pages/tablet/widgets/right_side_widget.dart';
import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

class TabletPage extends StatelessWidget {
  const TabletPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        return Scaffold(
          body: Row(
            children: [
              LeftSideWidget(
                sizingInformation: sizingInformation,
              ),
              Expanded(
                  child: RightSideWidget(
                sizingInformation: sizingInformation,
              )),
            ],
          ),
        );
      },
    );
  }
}

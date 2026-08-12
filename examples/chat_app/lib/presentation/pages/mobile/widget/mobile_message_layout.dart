import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';

class MobileMessageLayout extends StatelessWidget {
  final String? uid;
  final String? type;
  final String text;
  final String time;
  final Color? color;
  final TextAlign? align;
  final CrossAxisAlignment boxAlignment;
  final BubbleNip? nip;
  final String senderName;
  final String? senderId;
  final MainAxisAlignment boxMainAxisAlignment;

  const MobileMessageLayout({
    Key? key,
    this.uid,
    this.type,
    required this.text,
    required this.time,
    this.color,
    this.align,
    required this.boxAlignment,
    this.nip,
    required this.senderName,
    this.senderId,
    required this.boxMainAxisAlignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: boxAlignment,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: boxMainAxisAlignment,
          children: [
            color == Colors.blue
                ? Container(
                    height: 35,
                    width: 35,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: const BorderRadius.all(Radius.circular(55))),
                    child: Image.asset("assets/profile_default.png"),
                  )
                : const Text(
                    "",
                    style: TextStyle(fontSize: 0),
                  ),
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.all(3),
              child: Bubble(
                color: color,
                nip: nip,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    color == Colors.green[300]
                        ? Text(
                            "Me",
                            textAlign: align,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          )
                        : Text(
                            senderName,
                            textAlign: align,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 250),
                      child: Text(
                        text == "" ? "" : text,
                        textAlign: align,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    Text(
                      time,
                      textAlign: align,
                      style: const TextStyle(fontSize: 14),
                    )
                  ],
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}

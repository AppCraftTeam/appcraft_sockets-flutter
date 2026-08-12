import 'dart:async';

import 'package:bubble/bubble.dart';
import 'package:example/presentation/bloc/communication/communication_cubit.dart';
import 'package:example/presentation/pages/widget/message_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:responsive_builder/responsive_builder.dart';

class SingleChatPageWeb extends StatefulWidget {
  final String uid;
  final String userName;

  const SingleChatPageWeb({Key? key, required this.uid, required this.userName}) : super(key: key);

  @override
  _SingleChatPageWebState createState() => _SingleChatPageWebState();
}

class _SingleChatPageWebState extends State<SingleChatPageWeb> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    BlocProvider.of<CommunicationCubit>(context).getTextMessages();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunicationCubit, CommunicationState>(
      builder: (context, state) {
        if (state is CommunicationLoaded) {
          return _bodyWidget(state);
        }
        return _loadingWidget();
      },
    );
  }

  Widget _bodyWidget(CommunicationLoaded messages) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/background_img.png",
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              _headerWidget(),
              _listMessagesWidget(messages),
              _sendTextMessageWidget(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loadingWidget() {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/background_img.png",
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              _headerWidget(),
              const Expanded(
                  child: Center(
                child: CircularProgressIndicator(),
              )),
              _sendTextMessageWidget(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80),
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
          gradient: LinearGradient(
        colors: [
          Colors.indigo[400]!,
          Colors.blue[300]!,
        ],
      )),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(width: 40, height: 40, child: Image.asset("assets/logo.png")),
              const Text(
                "Global Chat Room",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            widget.userName,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }

  Widget _listMessagesWidget(CommunicationLoaded state) {
    final messages = state.messages;
    final dateFormat = DateFormat('hh:mm a');
    Future.delayed(const Duration(milliseconds: 100),
        () => _scrollController.jumpTo(_scrollController.position.maxScrollExtent));
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          itemCount: messages.length,
          itemBuilder: (_, index) {
            return messages[index].senderId == widget.uid
                ? MessageLayout(
                    type: messages[index].type,
                    senderId: messages[index].senderId,
                    senderName: messages[index].senderName,
                    text: messages[index].message,
                    time: dateFormat.format(messages[index].time),
                    color: Colors.green[300],
                    align: TextAlign.left,
                    nip: BubbleNip.rightTop,
                    boxAlignment: CrossAxisAlignment.end,
                    boxMainAxisAlignment: MainAxisAlignment.end,
                    uid: widget.uid,
                  )
                : MessageLayout(
                    type: messages[index].type,
                    senderName: messages[index].senderName,
                    text: messages[index].message,
                    time: dateFormat.format(messages[index].time),
                    color: Colors.blue,
                    align: TextAlign.left,
                    nip: BubbleNip.leftTop,
                    boxAlignment: CrossAxisAlignment.start,
                    boxMainAxisAlignment: MainAxisAlignment.start,
                  );
          },
        ),
      ),
    );
  }

  Widget _sendTextMessageWidget() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 80),
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(0.0)),
            border: Border.all(color: Colors.black.withOpacity(.4), width: 2)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _emojiWidget(),
                const SizedBox(
                  width: 8,
                ),
                _textFieldWidget(),
              ],
            ),
            Row(
              children: [
                _micWidget(),
                const SizedBox(
                  width: 8,
                ),
                _sendMessageButton(),
              ],
            )
          ],
        ),
      ),
    );
  }

  _emojiWidget() {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(.2),
          borderRadius: const BorderRadius.all(Radius.circular(40))),
      child: const Icon(
        Icons.emoji_symbols,
        color: Colors.white,
      ),
    );
  }

  _micWidget() {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(.2),
          borderRadius: const BorderRadius.all(Radius.circular(40))),
      child: const Icon(
        Icons.mic,
        color: Colors.white,
      ),
    );
  }

  _textFieldWidget() {
    return ResponsiveBuilder(
      builder: (_, sizingInformation) {
        return SizedBox(
          width: sizingInformation.screenSize.width * 0.65,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 60,
            ),
            child: Scrollbar(
              child: TextField(
                controller: _messageController,
                maxLines: null,
                decoration: const InputDecoration(
                    border: InputBorder.none, hintText: "Type Feel Free <3 ..."),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sendMessageButton() {
    return InkWell(
      onTap: () {
        if (_messageController.text.isNotEmpty) {
          _sendTextMessage();
          _messageController.clear();
        }
      },
      child: Container(
        height: 50,
        width: 50,
        decoration: const BoxDecoration(
            color: Colors.green, borderRadius: BorderRadius.all(Radius.circular(40))),
        child: const Icon(
          Icons.send,
          color: Colors.white,
        ),
      ),
    );
  }

  void _sendTextMessage() {
    BlocProvider.of<CommunicationCubit>(context)
        .sendTextMsg(uid: widget.uid, name: widget.userName, message: _messageController.text);
  }
}

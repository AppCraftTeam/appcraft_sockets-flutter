import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:example/domain/entities/simple_message.dart';
import 'package:example/domain/usecase/get_messages_usecase.dart';
import 'package:example/domain/usecase/send_text_message_usecase.dart';

part 'communication_state.dart';

class CommunicationCubit extends Cubit<CommunicationState> {
  final GetMessagesUseCase getMessagesUseCase;
  final SendTextMessageUseCase sendTextMessageUseCase;

  final List<SimpleMessage> _messages = [];

  CommunicationCubit({required this.getMessagesUseCase, required this.sendTextMessageUseCase})
      : super(CommunicationInitial());

  Future<void> sendTextMsg(
      {required String name, required String uid, required String message}) async {
    await sendTextMessageUseCase.call(SimpleMessage(uid, name, "TEXT", DateTime.now(), message));
  }

  void getTextMessages() {
    final stream = getMessagesUseCase();
    stream.listen((msg) {
      _messages.add(msg);
      emit(CommunicationLoaded(messages: _messages));
    });
    emit(CommunicationLoaded(messages: _messages));
  }
}

part of 'communication_cubit.dart';

abstract class CommunicationState {
  const CommunicationState();
}

class CommunicationInitial extends CommunicationState {}

class CommunicationLoading extends CommunicationState {}

class CommunicationLoaded extends CommunicationState {
  final List<SimpleMessage> messages;

  const CommunicationLoaded({required this.messages});
}

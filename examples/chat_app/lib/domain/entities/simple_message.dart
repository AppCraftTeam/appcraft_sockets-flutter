import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'simple_message.g.dart';

@JsonSerializable()
class SimpleMessage extends Equatable {
  final String? senderId;
  final String senderName;
  final String? type;
  @JsonKey(fromJson: _timeFromJson)
  final DateTime time;
  final String message;

  const SimpleMessage(this.senderId, this.senderName, this.type, this.time, this.message);

  factory SimpleMessage.fromJson(Map<String, dynamic> json) => _$SimpleMessageFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleMessageToJson(this);

  @override
  List<Object?> get props => [senderId, senderName, type, time, message];
}

DateTime _timeFromJson(dynamic jsonVal) {
  try {
    return DateTime.parse(jsonVal);
  } catch (_) {
    return DateTime.now();
  }
}

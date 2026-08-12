// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simple_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimpleMessage _$SimpleMessageFromJson(Map<String, dynamic> json) => SimpleMessage(
      json['senderId'] as String?,
      json['senderName'] as String,
      json['type'] as String?,
      _timeFromJson(json['time']),
      json['message'] as String,
    );

Map<String, dynamic> _$SimpleMessageToJson(SimpleMessage instance) => <String, dynamic>{
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'type': instance.type,
      'time': instance.time.toIso8601String(),
      'message': instance.message,
    };

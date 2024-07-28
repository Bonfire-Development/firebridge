import 'dart:async';

import 'package:firebridge/firebridge.dart';
import 'package:firebridge/src/http/managers/voice_gateway_manager.dart';
import 'package:firebridge/src/models/voice_gateway/event.dart';
import 'package:firebridge/src/models/voice_gateway/opcode.dart';
import 'package:firebridge/src/models/voice_gateway/voice.dart';
import 'package:firebridge/src/voice_gateway/connection.dart';
import 'package:firebridge/src/voice_gateway/event_mixin.dart';
import 'package:firebridge/src/voice_gateway/event_parser.dart';
import 'package:firebridge/src/voice_gateway/message.dart';

class VoiceGateway extends VoiceGatewayManager
    with VoiceEventParser, VoiceEventMixin {
  /// The [VoiceGatewayUser] instance used to configure this [VoiceGateway].
  final VoiceGatewayUser voiceGatewayUser;

  /// The [VoiceConnection] instance used to communicate with the Gateway.
  final VoiceConnection connection;

  /// The endpoint of the Gateway.
  final Uri endpoint;

  late final Stream<VoiceGatewayEvent> events = connection.events;

  /// Create a new [VoiceGateway].
  VoiceGateway(this.voiceGatewayUser, this.connection, this.endpoint)
      : super.create() {
    connection.events.listen((event) {
      connection.add(VoiceSend(opcode: VoiceOpcode.identify, data: {
        "server_id": voiceGatewayUser.serverId.value.toString(),
        "user_id": voiceGatewayUser.userId.value.toString(),
        "session_id": voiceGatewayUser.sessionId,
        "token": voiceGatewayUser.token,
        "video": true,
        "streams": [],
      }));
    });
  }

  static Future<VoiceGateway> connect(
      VoiceGatewayUser voiceGatewayUser, Uri voiceConnectionUri) async {
    return VoiceGateway(
      voiceGatewayUser,
      await VoiceConnection.connect(voiceConnectionUri.toString()),
      voiceConnectionUri,
    );
  }

  Future<void> disconnect() async {
    await connection.websocket.close();
  }

  Future<void> sendVoiceIdentify(VoiceIdentifyBuilder builder) async {
    connection.add(VoiceSend(
      opcode: VoiceOpcode.identify,
      data: builder.build(),
    ));
  }

  @override
  // TODO: implement apiOptions
  ApiOptions get apiOptions => throw UnimplementedError();

  @override
  Future<void> close() {
    // TODO: implement close
    throw UnimplementedError();
  }

  @override
  // TODO: implement httpHandler
  HttpHandler get httpHandler => throw UnimplementedError();

  @override
  // TODO: implement logger
  Logger get logger => throw UnimplementedError();

  @override
  // TODO: implement options
  ClientOptions get options => throw UnimplementedError();
}

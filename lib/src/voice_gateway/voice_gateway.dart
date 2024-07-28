import 'package:firebridge/firebridge.dart';
import 'package:firebridge/src/client.dart';
import 'package:firebridge/src/http/managers/voice_gateway_manager.dart';
import 'package:firebridge/src/models/voice_gateway/event.dart';
import 'package:firebridge/src/models/voice_gateway/opcode.dart';
import 'package:firebridge/src/models/voice_gateway/voice.dart';
import 'package:firebridge/src/voice_gateway/connection.dart';
import 'package:firebridge/src/voice_gateway/event_parser.dart';
import 'package:firebridge/src/voice_gateway/message.dart';
import 'package:firebridge/src/voice_gateway/runner.dart';

class VoiceGateway extends VoiceGatewayManager with VoiceEventParser {
  /// The [VoiceGatewayUser] instance used to configure this [VoiceGateway].
  final VoiceGatewayUser voiceGatewayUser;
  final VoiceConnection connection;
  final Uri endpoint;

  /// Create a new [VoiceGateway].
  VoiceGateway(this.voiceGatewayUser, this.connection, this.endpoint)
      : super.create() {
    // do connection stuff here

    print("IN GATEWAY1");

    VoiceData voiceData = VoiceData(
      endpoint: endpoint,
      token: voiceGatewayUser.token,
      sessionId: voiceGatewayUser.sessionId,
    );

    /*
    Messages are sent, events are received.
    I think I'm getting shards mixed up with actual requests being sent.

    Yeah... messages are a multithreaded concept, not a discord concent.
    Discord only uses events to my knowledge.
    */

    connection.events.listen((event) {
      print("Received event: $event");
      // print((event as VoiceHelloEvent).gatewayVersion);

      connection.add(VoiceSend(opcode: VoiceOpcode.identify, data: {
        "server_id": voiceGatewayUser.serverId.value.toString(),
        "user_id": voiceGatewayUser.userId.value.toString(),
        "session_id": voiceGatewayUser.sessionId,
        "token": voiceGatewayUser.token,
        "video": true,
        "streams": [],
      }));
      print("added!");
    });

    // runner.run(messages).listen((event) {
    //   if (event is VoiceErrorReceived) {
    //     print("Error received: ${event.error}");
    //   } else if (event is VoiceSent) {
    //     print("Sent event: ${event.payload}");
    //   } else {
    //     print("Received event: $event");
    //   }
    // });
  }

  static Future<VoiceGateway> connect(
      VoiceGatewayUser voiceGatewayUser, Uri voiceConnectionUri) async {
    return VoiceGateway(
      voiceGatewayUser,
      await VoiceConnection.connect(voiceConnectionUri.toString()),
      voiceConnectionUri,
    );
  }
}

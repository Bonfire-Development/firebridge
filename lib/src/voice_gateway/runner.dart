import 'dart:async';

import 'package:firebridge/src/voice_gateway/connection.dart';
import 'package:firebridge/src/voice_gateway/message.dart';

class VoiceRunner {
  /// The data needed to run the voice socket.
  final VoiceData voiceData;

  /// The current active connection.
  VoiceConnection? connection;

  VoiceRunner({
    required this.voiceData,
  });

  Stream<VoiceMessage> run(Stream<VoiceGatewayMessage> messages) async* {
    // Add messages to this controller for them to be sent back to the main isolate.
    final controller = StreamController<VoiceMessage>();

    // sendHandler is responsible for handling requests for this shard to send messages to the Gateway.
    // It is paused whenever this shard isn't ready to send messages.
    final sendController = StreamController<VoiceSend>();
    final sendHandler = sendController.stream.listen((e) async {
      try {
        await connection!.add(e);
      } catch (error, s) {
        controller.add(VoiceErrorReceived(error: error, stackTrace: s));

        // Prevent the recursive call to add() from looping too often.
        await Future.delayed(Duration(milliseconds: 100));
        // Try to send the event again, unless we are disposing (in which case the controller will be closed).
        if (!sendController.isClosed) {
          sendController.add(e);
        }
      }
    })
      ..pause();

    Future<void> asyncRun() async {
      final subscription = connection!.listen((event) async {
        print("Received event: $event");
      });
    }

    asyncRun().then((_) {
      controller.close();
      sendController.close();
      // identifyController.close();
      // messageHandler.cancel();
    });

    yield* controller.stream;
  }
}

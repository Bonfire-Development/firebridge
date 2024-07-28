import 'dart:async';
import 'dart:convert';

import 'package:firebridge/src/models/voice_gateway/event.dart';
import 'package:firebridge/src/voice_gateway/event_parser.dart';
import 'package:firebridge/src/voice_gateway/message.dart';
import 'package:universal_io/io.dart';

class VoiceConnection extends Stream<VoiceGatewayEvent>
    implements StreamSink<VoiceSend> {
  /// The connection to the Gateway.
  late WebSocket websocket;

  /// A stream on which [VoiceSent] events are added.
  Stream<VoiceSent> get onSent => _sentController.stream;
  final StreamController<VoiceSent> _sentController = StreamController();

  /// A stream of parsed events received from the Gateway.
  final Stream<VoiceGatewayEvent> events;

  VoiceConnection(this.websocket, this.events);

  static Future<VoiceConnection> connect(String gatewayUri) async {
    final connection = await WebSocket.connect(
      gatewayUri,
    );

    final parser = VoiceEventParser();
    final eventStream = connection.cast<dynamic>().map((event) {
      return parser.parseVoiceGatewayEvent(
          jsonDecode(event as String) as Map<String, Object?>);
    });

    return VoiceConnection(connection, eventStream.asBroadcastStream());
  }

  @override
  Future<void> add(VoiceSend event) async {
    final payload = {
      'op': event.opcode.value,
      'd': event.data,
    };

    final encoded = jsonEncode(payload);
    websocket.add(encoded);
    _sentController.add(VoiceSent(payload: event));
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      websocket.addError(error, stackTrace);

  @override
  Future<void> addStream(Stream<VoiceSend> stream) => stream.forEach(add);

  @override
  Future<void> close([int code = 1000]) async {
    await websocket.close(code);
    await _sentController.close();
  }

  @override
  Future<void> get done => websocket.done.then((_) => _sentController.done);

  @override
  StreamSubscription<VoiceGatewayEvent> listen(
    void Function(VoiceGatewayEvent event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return events.listen(onData,
        cancelOnError: cancelOnError, onDone: onDone, onError: onError);
  }
}

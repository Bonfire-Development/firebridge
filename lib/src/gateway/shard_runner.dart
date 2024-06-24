import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:html' if (dart.library.io) 'dart:io' as io;

import 'package:archive/archive.dart';
import 'package:eterl/eterl.dart';
import 'package:firebridge/firebridge.dart';
import 'package:firebridge/src/api_options.dart';
import 'package:firebridge/src/errors.dart';
import 'package:firebridge/src/gateway/event_parser.dart';
import 'package:firebridge/src/gateway/message.dart';
import 'package:firebridge/src/models/gateway/event.dart';
import 'package:firebridge/src/models/gateway/opcode.dart';

import 'web_socket_web.dart' if (dart.library.io) 'web_socket_io.dart';

class ShardRunner {
  final ShardData data;
  Timer? heartbeatTimer;
  int? seq;
  String? sessionId;
  ShardConnection? connection;
  bool lastHeartbeatAcked = true;
  Stopwatch? heartbeatStopwatch;
  bool canResume = false;
  bool disposing = false;
  late Uri gatewayUri = originalGatewayUri;
  late final Uri originalGatewayUri =
      data.originalConnectionUri.replace(queryParameters: {
    ...data.originalConnectionUri.queryParameters,
    ...data.apiOptions.gatewayConnectionOptions,
  });

  ShardRunner(this.data);

  Stream<ShardMessage> run(Stream<GatewayMessage> messages) {
    final controller = StreamController<ShardMessage>();
    final controlSubscription = messages.listen((message) {
      if (message is Send) {
        connection!.add(message);
      }
      if (message is Dispose) {
        disposing = true;
        connection!.close();
      }
    })
      ..pause();

    Future<void> asyncRun() async {
      while (true) {
        try {
          lastHeartbeatAcked = true;
          if (!controlSubscription.isPaused) {
            controlSubscription.pause();
          }
          connection =
              await ShardConnection.connect(gatewayUri.toString(), this);
          final hello = await connection!.first;
          if (hello is! HelloEvent) {
            throw InvalidEventException('Expected HELLO on connection.');
          }
          controller.add(EventReceived(event: hello));
          startHeartbeat(hello.heartbeatInterval);
          if (canResume && seq != null && sessionId != null) {
            sendResume();
          } else {
            sendIdentify();
          }
          canResume = false;
          controlSubscription.resume();
          final subscription = connection!.listen((event) {
            if (event is RawDispatchEvent) {
              seq = event.seq;
              if (event.name == 'READY') {
                final resumeUri =
                    Uri.parse(event.payload['resume_gateway_url'] as String);
                gatewayUri = resumeUri.replace(queryParameters: {
                  ...resumeUri.queryParameters,
                  ...data.apiOptions.gatewayConnectionOptions,
                });
                sessionId = event.payload['session_id'] as String;
              }
            } else if (event is ReconnectEvent) {
              canResume = true;
              connection!.close();
            } else if (event is InvalidSessionEvent) {
              if (event.isResumable) {
                canResume = true;
              } else {
                canResume = false;
                gatewayUri = originalGatewayUri;
              }
              connection!.close();
            } else if (event is HeartbeatAckEvent) {
              lastHeartbeatAcked = true;
              heartbeatStopwatch = null;
            } else if (event is HeartbeatEvent) {
              connection!.add(Send(opcode: Opcode.heartbeat, data: seq));
            }
            controller.add(EventReceived(event: event));
          });
          await subscription.asFuture();
          if (disposing) {
            controller.add(Disconnecting(reason: 'Dispose requested'));
            return;
          }
          const resumableCodes = [
            null,
            1001,
            4000,
            4001,
            4002,
            4003,
            4007,
            4008,
            4009
          ];
          final closeCode = connection!.closeCode;
          canResume = canResume || resumableCodes.contains(closeCode);
          if (!canResume && (closeCode ?? 0) >= 4000) {
            controller.add(
                Disconnecting(reason: 'Received error close code: $closeCode'));
            return;
          }
        } catch (error, stackTrace) {
          controller.add(ErrorReceived(error: error, stackTrace: stackTrace));
        } finally {
          connection?.close();
          connection = null;
          heartbeatTimer?.cancel();
          heartbeatTimer = null;
          heartbeatStopwatch = null;
        }
      }
    }

    asyncRun().then((_) {
      controller.close();
      controlSubscription.cancel();
    });

    return controller.stream;
  }

  void heartbeat() {
    if (!lastHeartbeatAcked) {
      connection!.close(4000);
      return;
    }
    connection!.add(Send(opcode: Opcode.heartbeat, data: seq));
    lastHeartbeatAcked = false;
    heartbeatStopwatch = Stopwatch()..start();
  }

  void startHeartbeat(Duration heartbeatInterval) {
    heartbeatTimer = Timer(heartbeatInterval * Random().nextDouble(), () {
      heartbeat();
      heartbeatTimer = Timer.periodic(heartbeatInterval, (_) => heartbeat());
    });
  }

  void sendIdentify() {
    final properties = {
      'os': Platform.operatingSystem,
      'browser': 'firebridge',
      'device': 'firebridge',
    };
    connection!.add(Send(
      opcode: Opcode.identify,
      data: {
        'token': data.apiOptions.token,
        'properties': properties,
        if (data.apiOptions.compression == GatewayCompression.payload)
          'compress': true,
        if (data.apiOptions.largeThreshold != null)
          'large_threshold': data.apiOptions.largeThreshold,
        'shard': [data.id, data.totalShards],
        if (data.apiOptions.initialPresence != null)
          'presence': data.apiOptions.initialPresence!.build(),
        'intents': data.apiOptions.intents.value,
      },
    ));
  }

  void sendResume() {
    assert(sessionId != null && seq != null);
    connection!.add(Send(
      opcode: Opcode.resume,
      data: {
        'token': data.apiOptions.token,
        'session_id': sessionId,
        'seq': seq,
      },
    ));
  }
}

class ShardConnection extends Stream<GatewayEvent> implements StreamSink<Send> {
  final PlatformWebSocket websocket; // Use the platform-specific type alias
  final Stream<GatewayEvent> events;
  final ShardRunner runner;

  int? get closeCode => _closeCode;
  int? _closeCode;

  final Completer<void> _doneCompleter = Completer();

  ShardConnection(this.websocket, this.events, this.runner) {
    getWebSocketOnClose(websocket).listen((event) {
      _closeCode = isWeb ? event.code as int? : null;
      _doneCompleter.complete();
    });
  }

  static Future<ShardConnection> connect(
      String gatewayUri, ShardRunner runner) async {
    final PlatformWebSocket connection = createWebSocket(gatewayUri);
    if (!isWeb) setWebSocketBinaryType(connection);

    await getWebSocketOnOpen(connection).first;

    final uncompressedStream = switch (runner.data.apiOptions.compression) {
      GatewayCompression.transport => decompressTransport(
          getWebSocketOnMessage(connection)
              .map((event) => (event as ByteBuffer).asUint8List())),
      GatewayCompression.payload => decompressPayloads(
          getWebSocketOnMessage(connection).map((event) => switch (event) {
                ByteBuffer buffer => buffer.asUint8List(),
                var other => other,
              })),
      GatewayCompression.none =>
        getWebSocketOnMessage(connection).map((event) => switch (event) {
              ByteBuffer buffer => buffer.asUint8List(),
              var other => other,
            }),
    };

    final dataStream = switch (runner.data.apiOptions.payloadFormat) {
      GatewayPayloadFormat.json => parseJson(uncompressedStream),
      GatewayPayloadFormat.etf =>
        parseEtf(uncompressedStream.cast<List<int>>()),
    };

    final parser = EventParser();
    final eventStream = dataStream.cast<Map<String, Object?>>().map((event) =>
        parser.parseGatewayEvent(event,
            heartbeatLatency: runner.heartbeatStopwatch?.elapsed));

    return ShardConnection(connection, eventStream.asBroadcastStream(), runner);
  }

  @override
  StreamSubscription<GatewayEvent> listen(
    void Function(GatewayEvent event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return events.listen(onData,
        cancelOnError: cancelOnError, onDone: onDone, onError: onError);
  }

  @override
  void add(Send event) {
    final payload = {
      'op': event.opcode.value,
      'd': event.data,
    };

    final encoded = switch (runner.data.apiOptions.payloadFormat) {
      GatewayPayloadFormat.json => jsonEncode(payload),
      GatewayPayloadFormat.etf => eterl.pack(payload),
    };

    assert(encoded is String || encoded is TypedData);

    sendWebSocketData(websocket, encoded);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    // Implement error handling logic here
    print('Error: $error');
    if (stackTrace != null) {
      print('StackTrace: $stackTrace');
    }
  }

  @override
  Future<void> addStream(Stream<Send> stream) => stream.forEach(add);

  @override
  Future<void> close([int? code]) async => closeWebSocket(websocket, code);

  @override
  Future<void> get done => _doneCompleter.future;
}

Stream<dynamic> decompressTransport(Stream<List<int>> raw) =>
    throw JsDisabledError('transport compression');

Stream<dynamic> decompressPayloads(Stream<dynamic> raw) => raw.map((message) {
      if (message is String) {
        return message;
      } else {
        return ZLibDecoder().decodeBytes(message as List<int>);
      }
    });

Stream<dynamic> parseJson(Stream<dynamic> raw) => raw.map((message) {
      final source =
          message is String ? message : utf8.decode(message as List<int>);
      return jsonDecode(source);
    });

Stream<dynamic> parseEtf(Stream<List<int>> raw) =>
    raw.transform(eterl.unpacker());

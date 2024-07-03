import 'dart:async';
import 'dart:isolate';

import 'package:firebridge/src/builders/guild/channel_statuses.dart';
import 'package:firebridge/src/builders/guild/guild_subscriptions_bulk.dart';
import 'package:logging/logging.dart';
import 'package:firebridge/src/api_options.dart';
import 'package:firebridge/src/builders/voice.dart';
import 'package:firebridge/src/client.dart';
import 'package:firebridge/src/gateway/message.dart';
import 'package:firebridge/src/gateway/shard_runner.dart';
import 'package:firebridge/src/models/gateway/event.dart';
import 'package:firebridge/src/models/gateway/opcode.dart';
import 'package:firebridge/src/models/snowflake.dart';

import 'package:firebridge/src/utils/is_web_web.dart'
    if (dart.library.io) 'package:firebridge/src/utils/is_web_io.dart';

/// {@template shard}
/// A single connection to Discord's Gateway.
/// {@endtemplate}
class Shard extends Stream<ShardMessage> implements StreamSink<GatewayMessage> {
  /// The ID of this shard.
  final int id;

  /// The isolate this shard's handler is running in.
  final Isolate? isolate;

  /// A future that completes once the shard runner exits.
  @Deprecated('Only present for JS support')
  // ignore: non_constant_identifier_names
  final Future<void>? JS_ONLY_exitFuture;

  /// A sink to which events are added to be sent to the runner.
  @Deprecated('Only present for JS support')
  // ignore: non_constant_identifier_names
  final Sink<dynamic>? JS_ONLY_sendSink;

  /// The stream on which events from the runner are received.
  final Stream<dynamic> receiveStream;

  final StreamController<ShardMessage> _rawReceiveController =
      StreamController();
  final StreamController<ShardMessage> _transformedReceiveController =
      StreamController.broadcast();

  /// The port on which events are sent to the runner.
  final SendPort sendPort;

  final StreamController<GatewayMessage> _sendController = StreamController();

  /// The client this [Shard] is for.
  final NyxxGateway client;

  /// The logger used by this shard.
  Logger get logger => Logger('${client.options.loggerName}.Shards[$id]');

  final Completer<void> _doneCompleter = Completer();

  Duration _latency = Duration.zero;

  /// The latency on this shard's connection.
  ///
  /// This is updated for each [HeartbeatAckEvent] received. If no [HeartbeatAckEvent] has been received, this will be [Duration.zero].
  Duration get latency => _latency;

  /// Create a new [Shard].
  Shard(this.id, this.receiveStream, this.sendPort, this.client, this.isolate,
      this.JS_ONLY_exitFuture, this.JS_ONLY_sendSink) {
    client.initialized.then((_) {
      final sendStream = client.options.plugins.fold(
        _sendController.stream,
        (previousValue, plugin) =>
            plugin.interceptGatewayMessages(this, previousValue),
      );
      sendStream.listen(sendPort.send, cancelOnError: false, onDone: close);

      final transformedReceiveStream = client.options.plugins.fold(
        _rawReceiveController.stream,
        (previousValue, plugin) =>
            plugin.interceptShardMessages(this, previousValue),
      );
      transformedReceiveStream.pipe(_transformedReceiveController);
    });

    receiveStream.cast<ShardMessage>().pipe(_rawReceiveController);

    final subscription = listen((message) {
      if (message is Sent) {
        logger
          ..fine('Sent payload: ${message.payload.opcode.name}')
          ..finer(
              'Opcode: ${message.payload.opcode.value}, Data: ${message.payload.data}');
      } else if (message is ErrorReceived) {
        logger.warning(
            'Error: ${message.error}', message.error, message.stackTrace);
      } else if (message is Disconnecting) {
        logger.info('Disconnecting: ${message.reason}');
      } else if (message is EventReceived) {
        final event = message.event;

        if (event is! RawDispatchEvent) {
          logger.finer('Receive: ${event.opcode.name}');

          switch (event) {
            case InvalidSessionEvent(:final isResumable):
              logger.finest('Resumable: $isResumable');
              if (isResumable) {
                logger.info('Reconnecting: invalid session');
              } else {
                logger.warning('Reconnecting: unresumable invalid session');
              }
            case HelloEvent(:final heartbeatInterval):
              logger.finest('Heartbeat Interval: $heartbeatInterval');
            case ReconnectEvent():
              logger.info('Reconnecting: reconnect requested');
            case HeartbeatAckEvent(:final latency):
              _latency = latency;
            default:
              break;
          }
        } else {
          logger
            ..fine('Receive event: ${event.name}')
            ..finer('Seq: ${event.seq}, Data: ${event.payload}')
            ..finer('Opcode: ${event.opcode.value}, ');

          if (event.name == 'READY') {
            logger.info('Connected to Gateway');
          } else if (event.name == 'RESUMED') {
            logger.info('Reconnected to Gateway');
          }
        }
      } else if (message is RequestingIdentify) {
        logger.fine('Ready to identify');
      }
    });

    subscription.asFuture().then((value) {
      // Can happen if the shard closes unexpectedly.
      // Prevents further calls to close() from attempting to add events.
      if (!_doneCompleter.isCompleted) {
        _doneCompleter.complete(value);
      }
    });
  }

  /// Connect to the Gateway using the provided parameters.
  static Future<Shard> connect(
      int id,
      int totalShards,
      GatewayApiOptions apiOptions,
      Uri connectionUri,
      NyxxGateway client) async {
    final logger = Logger('${client.options.loggerName}.Shards[$id]');

    final receivePort = ReceivePort('Shard #$id message stream (main)');
    final receiveStream = receivePort.asBroadcastStream();

    logger.fine('Spawning shard runner');

    Isolate? isolate;
    if (!isWeb) {
      isolate = await Isolate.spawn(
        _isolateMain,
        debugName: 'Shard #$id runner',
        _IsolateSpawnData(
          totalShards: totalShards,
          id: id,
          apiOptions: apiOptions,
          originalConnectionUri: connectionUri,
          sendPort: receivePort.sendPort,
        ),
      );
    }

    ReceivePort? exitPort;
    if (!isWeb) {
      exitPort = ReceivePort('Shard #$id exit listener');
      isolate!.addOnExitListener(exitPort.sendPort);
      exitPort.listen((_) {
        logger.info('Shard exited');

        receivePort.close();
        exitPort!.close();
      });
    } else {
      final sendSink = StreamController<dynamic>();

      final exitFuture = _isolateMainWeb(_IsolateSpawnData(
        totalShards: totalShards,
        id: id,
        apiOptions: apiOptions,
        originalConnectionUri: connectionUri,
        sendSink: sendSink,
      ));

      exitFuture.then((_) {
        logger.info('Shard exited');

        receivePort.close();
        exitPort!.close();
        sendSink.close();
      });
    }

    final sendPort = await receiveStream.first as SendPort;

    logger.fine('Shard runner ready');

    return Shard(id, receiveStream, sendPort, client, isolate, null, null);
  }

  /// Update the client's voice state on this shard.
  void updateVoiceState(Snowflake guildId, GatewayVoiceStateBuilder builder) {
    add(Send(opcode: Opcode.voiceStateUpdate, data: {
      'guild_id': guildId.toString(),
      ...builder.build(),
    }));
  }

  void updateChannelStatusesGuild(
      Snowflake guildId, ChannelStatusesBuilder builder) {
    add(Send(opcode: Opcode.guildSubscriptionsBulk, data: {
      'guild_id': guildId.toString(),
      ...builder.build(),
    }));
  }

  void updateguildSubscriptionsBulk(
      Snowflake guildId, GuildSubscriptionsBulkBuilder builder) {
    add(Send(opcode: Opcode.guildSubscriptionsBulk, data: {
      ...builder.build(),
    }));
  }

  @override
  void add(GatewayMessage event) {
    if (event is Send) {
      logger
        ..fine('Sending: ${event.opcode.name}')
        ..finer('Opcode: ${event.opcode.value}, Data: ${event.data}');
    } else if (event is Dispose) {
      logger.info('Disposing');
    } else if (event is Identify) {
      logger.info('Connecting to Gateway');
    }

    _sendController.add(event);
  }

  @override
  StreamSubscription<ShardMessage> listen(
    void Function(ShardMessage event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _transformedReceiveController.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  Future<void> close() {
    if (_doneCompleter.isCompleted) {
      return _doneCompleter.future;
    }

    Future<void> doClose() async {
      add(Dispose());

      _sendController.close();
      // _rawReceiveController and _transformedReceiveController are closed by the piped
      // receive port stream being closed.

      // Give the isolate time to shut down cleanly, but kill it if it takes too long.
      try {
        // Wait for disconnection confirmation.
        await firstWhere((message) => message is Disconnecting)
            .then(drain)
            .timeout(const Duration(seconds: 5));
      } on TimeoutException {
        logger.warning('Isolate took too long to shut down, killing it');
        if (!isWeb) {
          isolate!.kill(priority: Isolate.immediate);
        }
      }
    }

    _doneCompleter.complete(doClose());
    return _doneCompleter.future;
  }

  @override
  Future<void> get done => _doneCompleter.future;

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      throw UnimplementedError();

  @override
  Future<void> addStream(Stream<GatewayMessage> stream) => stream.forEach(add);
}

class _IsolateSpawnData extends ShardData {
  final SendPort? sendPort;
  final Sink<dynamic>? sendSink;

  _IsolateSpawnData({
    required super.totalShards,
    required super.id,
    required super.apiOptions,
    required super.originalConnectionUri,
    this.sendPort,
    this.sendSink,
  });
}

void _isolateMain(_IsolateSpawnData data) async {
  final receivePort = ReceivePort('Shard #${data.id} message stream (isolate)');
  data.sendPort!.send(receivePort.sendPort);

  final runner = ShardRunner(data);

  runner.run(receivePort.cast<GatewayMessage>()).listen(
    (message) {
      try {
        data.sendPort!.send(message);
      } on ArgumentError {
        // The only message with anything custom should be ErrorReceived
        assert(message is ErrorReceived);
        message = message as ErrorReceived;
        data.sendPort!.send(ErrorReceived(
            error: message.error.toString(), stackTrace: message.stackTrace));
      }
    },
    onDone: () => receivePort.close(),
  );
}

Future<void> _isolateMainWeb(_IsolateSpawnData data) async {
  final sendSink = StreamController<dynamic>();
  data.sendSink!.add(sendSink);

  final runner = ShardRunner(data);

  final subscription =
      runner.run(sendSink.stream.cast<GatewayMessage>()).listen(
    (message) {
      try {
        data.sendSink!.add(message);
      } on ArgumentError {
        // The only message with anything custom should be ErrorReceived
        assert(message is ErrorReceived);
        message = message as ErrorReceived;
        data.sendSink!.add(ErrorReceived(
            error: message.error.toString(), stackTrace: message.stackTrace));
      }
    },
    onDone: () => sendSink.close(),
  );

  return subscription.asFuture();
}

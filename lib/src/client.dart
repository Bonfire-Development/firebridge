import 'package:logging/logging.dart';
import 'package:nyxx/src/builders/presence.dart';
import 'package:nyxx/src/builders/voice.dart';
import 'package:nyxx/src/client_options.dart';
import 'package:nyxx/src/event_mixin.dart';
import 'package:nyxx/src/gateway/gateway.dart';
import 'package:nyxx/src/http/handler.dart';
import 'package:nyxx/src/http/managers/gateway_manager.dart';
import 'package:nyxx/src/intents.dart';
import 'package:nyxx/src/manager_mixin.dart';
import 'package:nyxx/src/api_options.dart';
import 'package:nyxx/src/models/guild/guild.dart';
import 'package:nyxx/src/models/snowflake.dart';
import 'package:nyxx/src/plugin/plugin.dart';
import 'package:nyxx/src/utils/flags.dart';

/// A helper function to nest and execute calls to plugin connect methods.
Future<T> _doConnect<T extends Nyxx>(ApiOptions apiOptions, ClientOptions clientOptions, Future<T> Function() connect, List<NyxxPlugin> plugins) {
  connect = plugins.fold(connect, (previousConnect, plugin) => () => plugin.connect(apiOptions, clientOptions, previousConnect));
  return connect();
}

/// A helper function to nest and execute calls to plugin close methods.
Future<void> _doClose(Nyxx client, Future<void> Function() close, List<NyxxPlugin> plugins) {
  close = plugins.fold(close, (previousClose, plugin) => () => plugin.close(client, previousClose));
  return close();
}

/// The base class for clients interacting with the Discord API.
abstract class Nyxx {
  /// The options this client will use when connecting to the API.
  ApiOptions get apiOptions;

  /// The [HttpHandler] used by this client to make requests.
  HttpHandler get httpHandler;

  /// The options controlling the behavior of this client.
  ClientOptions get options;

  /// The logger for this client.
  Logger get logger;

  /// Create an instance of [NyxxRest] that can perform requests to the HTTP API and is
  /// authenticated with a bot token.
  static Future<NyxxRest> connectRest(String token, {RestClientOptions options = const RestClientOptions()}) =>
      connectRestWithOptions(RestApiOptions(token: token), options);

  /// Create an instance of [NyxxRest] using the provided options.
  static Future<NyxxRest> connectRestWithOptions(RestApiOptions apiOptions, [RestClientOptions clientOptions = const RestClientOptions()]) async {
    clientOptions.logger
      ..info('Connecting to the REST API')
      ..fine('Token: ${apiOptions.token}, Authorization: ${apiOptions.authorizationHeader}, User-Agent: ${apiOptions.userAgent}')
      ..fine('Plugins: ${clientOptions.plugins.map((plugin) => plugin.name).join(', ')}');

    return _doConnect(apiOptions, clientOptions, () async => NyxxRest._(apiOptions, clientOptions), clientOptions.plugins);
  }

  /// Create an instance of [NyxxGateway] that can perform requests to the HTTP API, connects
  /// to the gateway and is authenticated with a bot token.
  static Future<NyxxGateway> connectGateway(String token, Flags<GatewayIntents> intents, {GatewayClientOptions options = const GatewayClientOptions()}) =>
      connectGatewayWithOptions(GatewayApiOptions(token: token, intents: intents), options);

  /// Create an instance of [NyxxGateway] using the provided options.
  static Future<NyxxGateway> connectGatewayWithOptions(
    GatewayApiOptions apiOptions, [
    GatewayClientOptions clientOptions = const GatewayClientOptions(),
  ]) async {
    clientOptions.logger
      ..info('Connecting to the Gateway API')
      ..fine(
        'Token: ${apiOptions.token}, Authorization: ${apiOptions.authorizationHeader}, User-Agent: ${apiOptions.userAgent},'
        ' Intents: ${apiOptions.intents.value}, Payloads: ${apiOptions.payloadFormat.value}, Compression: ${apiOptions.compression.name},'
        ' Shards: ${apiOptions.shards?.join(', ')}, Total shards: ${apiOptions.totalShards}, Large threshold: ${apiOptions.largeThreshold}',
      )
      ..fine('Plugins: ${clientOptions.plugins.map((plugin) => plugin.name).join(', ')}');

    return _doConnect(apiOptions, clientOptions, () async {
      final client = NyxxGateway._(apiOptions, clientOptions);
      // We can't use client.gateway as it is not initialized yet
      final gatewayManager = GatewayManager(client);

      final gatewayBot = await gatewayManager.fetchGatewayBot();
      final gateway = await Gateway.connect(client, gatewayBot);

      return client..gateway = gateway;
    }, clientOptions.plugins);
  }

  /// Close this client and any underlying resources.
  ///
  /// The client should not be used after this is called and unexpected behavior may occur.
  Future<void> close();
}

/// A client that can make requests to the HTTP API and is authenticated with a bot token.
class NyxxRest with ManagerMixin implements Nyxx {
  @override
  final RestApiOptions apiOptions;

  @override
  final RestClientOptions options;

  @override
  late final HttpHandler httpHandler = HttpHandler(this);

  @override
  Logger get logger => options.logger;

  NyxxRest._(this.apiOptions, this.options);

  /// Add the current user to the thread with the ID [id].
  ///
  /// External references:
  /// * [ChannelManager.joinThread]
  /// * Discord API Reference: https://discord.com/developers/docs/resources/channel#join-thread
  Future<void> joinThread(Snowflake id) => channels.joinThread(id);

  /// Remove the current user from the thread with the ID [id].
  ///
  /// External references:
  /// * [ChannelManager.leaveThread]
  /// * Discord API Reference: https://discord.com/developers/docs/resources/channel#leave-thread
  Future<void> leaveThread(Snowflake id) => channels.leaveThread(id);

  /// List the guilds the current user is a member of.
  Future<List<PartialGuild>> listGuilds({Snowflake? before, Snowflake? after, int? limit}) =>
      users.listCurrentUserGuilds(before: before, after: after, limit: limit);

  @override
  Future<void> close() {
    logger.info('Closing client');
    return _doClose(this, () async => httpHandler.close(), options.plugins);
  }
}

/// A client that can make requests to the HTTP API, connects to the Gateway and is authenticated with a bot token.
class NyxxGateway with ManagerMixin, EventMixin implements NyxxRest {
  @override
  final GatewayApiOptions apiOptions;

  @override
  final GatewayClientOptions options;

  @override
  late final HttpHandler httpHandler = HttpHandler(this);

  /// The [Gateway] used by this client to send and receive Gateway events.
  // Initialized in connectGateway due to a circular dependency
  @override
  late final Gateway gateway;

  @override
  Logger get logger => options.logger;

  NyxxGateway._(this.apiOptions, this.options);

  @override
  Future<void> joinThread(Snowflake id) => channels.joinThread(id);

  @override
  Future<void> leaveThread(Snowflake id) => channels.leaveThread(id);

  @override
  Future<List<PartialGuild>> listGuilds({Snowflake? before, Snowflake? after, int? limit}) =>
      users.listCurrentUserGuilds(before: before, after: after, limit: limit);

  /// Update the client's voice state in the guild with the ID [guildId].
  void updateVoiceState(Snowflake guildId, GatewayVoiceStateBuilder builder) => gateway.updateVoiceState(guildId, builder);

  /// Update the client's presence on all shards.
  void updatePresence(PresenceBuilder builder) => gateway.updatePresence(builder);

  @override
  Future<void> close() {
    logger.info('Closing client');
    return _doClose(this, () async {
      await gateway.close();
      httpHandler.close();
    }, options.plugins);
  }
}

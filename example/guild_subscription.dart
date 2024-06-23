import 'package:firebridge/firebridge.dart';

void main() async {
  final client = await Nyxx.connectGateway(
    "",
    GatewayIntents.all,
    // options: GatewayClientOptions(
    //     plugins: [Logging(logLevel: Level.ALL), cliIntegration]),
  );

  client.updateGuildSubscriptionsBulk(
    GuildSubscriptionsBulkBuilder()
      ..subscriptions = [
        GuildSubscription(
          guildId: Snowflake(820745488231301210),
          typing: true,
          channels: [
            GuildSubscriptionChannel(
              channelId: Snowflake(820745488231301213),
              memberRange: GuildMemberRange(
                lowerMemberBound: 0,
                upperMemberBound: 99,
              ),
            ),
          ],
        ),
      ],
  );

  client.onMessageCreate.listen((event) async {
    print(event.message.content);
  });
}

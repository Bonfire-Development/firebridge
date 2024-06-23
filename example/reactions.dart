import 'package:firebridge/firebridge.dart';
import 'package:firebridge/src/builders/guild/channel_statuses.dart';

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
          channels: {
            Snowflake(1233447567199834267):
                GuildMemberRange(lowerMemberBound: 0, upperMemberBound: 99),
          },
        ),
      ],
  );

  client.onMessageCreate.listen((event) async {
    print(event.message.content);
    // if (event.message.content.contains('nyxx_resp403_123123123')) {
    // print(event.message.content);
    // await event.message.react(ReactionBuilder(name: '❤️', id: null));
    // }
  });
}

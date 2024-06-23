import 'package:firebridge/firebridge.dart';
import 'package:firebridge/src/builders/guild/channel_statuses.dart';

void main() async {
  final client = await Nyxx.connectGateway(
    "",
    GatewayIntents.all,
    // options: GatewayClientOptions(
    //     plugins: [Logging(logLevel: Level.ALL), cliIntegration]),
  );

  // client.channelStatusesUpdate(Snowflake(820745488231301210),
  //     ChannelStatusesBuilder()..guildId = Snowflake(820745488231301210));
  // wait 2
  await Future.delayed(Duration(seconds: 2));
  client.updateGuildSubscriptionsBulk(
    Snowflake(662267976984297473),
    GuildSubscriptionsBulkBuilder()
      ..subscriptions = {
        Snowflake(662267976984297473): GuildSubscription(
          channels: {
            Snowflake(1008571027565072494):
                GuildMemberRange(lowerMemberBound: 0, upperMemberBound: 98),
          },
        ),
      },
  );

  client.onMessageCreate.listen((event) async {
    print(event.message.content);
    // if (event.message.content.contains('nyxx_resp403_123123123')) {
    // print(event.message.content);
    // await event.message.react(ReactionBuilder(name: '❤️', id: null));
    // }
  });
}

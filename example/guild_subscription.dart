import 'package:firebridge/firebridge.dart';

void main() async {
  final client = await Nyxx.connectGateway(
    "",
    GatewayIntents.all,
    options: GatewayClientOptions(
        plugins: [Logging(logLevel: Level.ALL), cliIntegration]),
  );

  client.updateGuildSubscriptionsBulk(
    GuildSubscriptionsBulkBuilder()
      ..subscriptions = [
        GuildSubscription(
          guildId: Snowflake(1238277719511400488),
          typing: true,
          threads: true,
          memberUpdates: false,
          activities: true,
          threadMemberLists: [],
          members: [],
          channels: [
            GuildSubscriptionChannel(
              channelId: Snowflake(1238277720023240805),
              memberRange: GuildMemberRange(
                lowerMemberBound: 0,
                upperMemberBound: 99,
              ),
            ),
          ],
        ),
      ],
  );

  // client.onVoiceServerUpdate.listen((event) async {
  //   print(event.);
  // });

  client.onMessageCreate.listen((event) async {
    // print(event.message.content);
  });

  client.onChannelUnread.listen((event) async {});

  // client.onGuildMemberListUpdate.listen((event) async {
  //   // print(event);
  //   if (event.eventType == MemberListUpdateType.sync) {
  //     print(event.memberList![2][0]);
  //   }
  // });
}

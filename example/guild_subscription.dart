import 'package:firebridge/firebridge.dart';
import 'package:firebridge/src/utils/date.dart';

void main() async {
  final client = await Nyxx.connectGateway(
    "",
    GatewayIntents.all,
    options: GatewayClientOptions(
        plugins: [Logging(logLevel: Level.OFF), cliIntegration]),
  );

  client.updateGuildSubscriptionsBulk(
    GuildSubscriptionsBulkBuilder()
      ..subscriptions = [
        GuildSubscription(
          guildId: Snowflake(1057441464449249370),
          typing: true,
          threads: true,
          memberUpdates: false,
          activities: true,
          threadMemberLists: [],
          members: [],
          channels: [
            GuildSubscriptionChannel(
              channelId: Snowflake(1057441464449249371),
              memberRange:
                  GuildMemberRange(lowerMemberBound: 0, upperMemberBound: 99),
            ),
          ],
        ),
      ],
  );

  // client.onVoiceServerUpdate.listen((event) async {
  //   print(event.);
  // });

  client.onMessageCreate.listen((event) async {
    // print("GOT MESSAGE!");
    // print(DiscordDateUtils.packLastViewed(DateTime.now()));
    event.message.manager.acknowledge(event.message.id);
  });

  client.onChannelUnread.listen((event) async {
    // print("got unread!");
    // print(event.channelUnreadUpdates.first.readState.lastViewed);
  });

  // client.onGuildMemberListUpdate.listen((event) async {
  //   // print(event);
  //   if (event.eventType == MemberListUpdateType.sync) {
  //     print(event.memberList![2][0]);
  //   }
  // });

  client.onMessageAck.listen((event) async {
    // print("got ack!");
    // print(event.channel);
    // print("GOT ACK!");
    // print(event.messageId);
  });

  client.onReady.listen((event) async {
    client.updateVoiceState(
        Snowflake(1238277719511400488),
        GatewayVoiceStateBuilder(
          channelId: Snowflake(1238277720023240805),
          isMuted: false,
          isDeafened: false,
          isStreaming: false,
        ));
  });
}

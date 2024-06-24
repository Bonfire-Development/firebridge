import 'package:firebridge/firebridge.dart';

void main() async {
  final client = await Nyxx.connectGateway(
    "",
    GatewayIntents.all,
  );

  client.updateGuildSubscriptionsBulk(
    GuildSubscriptionsBulkBuilder()
      ..subscriptions = [
        GuildSubscription(
          guildId: Snowflake(820745488231301210),
          typing: true,
          threads: true,
          memberUpdates: false,
          activities: true,
          threadMemberLists: [],
          members: [],
          channels: [
            GuildSubscriptionChannel(
              channelId: Snowflake(1233447567199834267),
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
    // print(event.message.content);
  });

  client.onGuildMemberListUpdate.listen((event) async {
    // print(event);
    if (event.eventType == MemberListUpdateType.sync) {
      print(event.memberList![2][0]);
    }
  });
}

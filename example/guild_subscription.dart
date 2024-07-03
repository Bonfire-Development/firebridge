import 'package:firebridge/firebridge.dart';

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
          guildId: Snowflake(1238277719511400488),
          typing: true,
          threads: true,
          memberUpdates: false,
          activities: true,
          threadMemberLists: [],
          members: [],
          channels: [],
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

  client.onReady.listen((event) async {
    print("got on ready");
    print(event.guilds.first);
    // print(event.userSettings);
    // print(event.userGuildSettings);
    // for (var readState in event.readStates) {
    //   print("${readState.id}: ${readState.mentionCount}");
    // }

    // for (var privateChannel in event.privateChannels) {
    //   print(privateChannel.recipients);
    // }
    // print(event.application);
  });
}

import 'package:firebridge/firebridge.dart';
import 'package:firebridge/src/utils/date.dart';

String gatewayToken = "";

void main() async {
  final client = await Nyxx.connectGateway(
    gatewayToken,
    GatewayIntents.all,
    options: GatewayClientOptions(
        plugins: [Logging(logLevel: Level.WARNING), cliIntegration]),
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
    /*
    Ready is called a LOT only when joining VC. I think this is because the
    gateway only checks validates the event name, and not the opcode.

    I need to find a way to differentiate between the two.
    */
    // print("Ready!");
    Snowflake guildId = Snowflake(1238277719511400488);
    Snowflake channelId = Snowflake(1238277720023240805);

    client.updateVoiceState(
        guildId,
        GatewayVoiceStateBuilder(
          channelId: channelId,
          isMuted: false,
          isDeafened: false,
          isStreaming: false,
        ));
    /*
      server_id	snowflake	The ID of the guild or private channel being connecting to
      user_id	snowflake	The ID of the current user
      session_id	string	The session ID of the current session
      token	string	The voice token for the current session
      video?	boolean	Whether or not this connection supports video
      streams?	array[stream object]	An array of video stream objects
    */
    String? token;
    String? sessionId;
    bool hasSentIdentify = false;
    void sendIdentify() {
      if (hasSentIdentify) return;
      hasSentIdentify = true;
      // // print("sending identify!");
      // client.sendVoiceIdentify(
      //     guildId,
      //     VoiceIdentifyBuilder(
      //       guildId: guildId,
      //       userId: Snowflake(1238277719511400488),
      //       sessionId: sessionId!,
      //       token: token!,
      //     ));
    }

    client.onVoiceServerUpdate.listen((event) async {
      // print("GOT VOICE SERVER UPDATE!");
      token = event.token;
      print(event.endpoint);
      if (token != null && sessionId != null) sendIdentify();
    });

    client.onVoiceStateUpdate.listen((event) async {
      // print("GOT VOICE STATE UPDATE!");
      sessionId = event.state.sessionId;

      if (token != null && sessionId != null) sendIdentify();
    });
  });
}

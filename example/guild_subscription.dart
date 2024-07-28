import 'package:firebridge/firebridge.dart';

String gatewayToken = "";

void main() async {
  final client = await Nyxx.connectGateway(
    gatewayToken,
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
    print("Client Ready");
    /*
    Ready is called a LOT only when joining VC. I think this is because the
    gateway only checks validates the event name, and not the opcode.

    I need to find a way to differentiate between the two.

    Nope, it just crashes :D
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
          isStreaming: true,
        ));

    // subscribe to guild bulk subscriptions
    // client.updateGuildSubscriptionsBulk(
    //   GuildSubscriptionsBulkBuilder()
    //     ..subscriptions = [
    //       GuildSubscription(
    //         typing: true,
    //         memberUpdates: true,
    //         channels: [
    //           GuildSubscriptionChannel(
    //             channelId: channelId,
    //             memberRange: GuildMemberRange(
    //               lowerMemberBound: 0,
    //               upperMemberBound: 5,
    //             ),
    //           )
    //         ],
    //         guildId: guildId,
    //       )
    //     ],
    // );

    // client.onGuildMemberListUpdate.listen((event) async {
    //   print("update!");
    //   event.memberList?.forEach((element) {
    //     if (element.first is! Member) return;
    //     print((element.first as Member).initialPresence);
    //   });
    //   // print("got member list update!");
    //   // print(event.memberList![0][0]);
    // });

    String? token;
    String? sessionId;
    String? endpoint;
    bool hasSentIdentify = false;
    void sendIdentify() async {
      if (hasSentIdentify) return;
      hasSentIdentify = true;
      // print("sending identify!");
      // client.sendVoiceIdentify(
      //     guildId,
      //     VoiceIdentifyBuilder(
      //       guildId: guildId,
      //       userId: Snowflake(1238277719511400488),
      //       sessionId: sessionId!,
      //       token: token!,
      //     ));
      VoiceGateway voiceClient = await Nyxx.connectVoiceGateway(
        VoiceGatewayUser(
          serverId: guildId,
          userId: Snowflake(949415879274291251),
          sessionId: sessionId!,
          token: token!,
          maxSecureFramesVersion: 0,
          video: true,
          streams: [],
        ),
        Uri.parse("wss://${endpoint!}"),
      );

      voiceClient.onReady.listen((event) {
        print("Voice Client Ready");
        // print("got voice client event!");
        // print(event.);
        // Future.delayed(Duration(seconds: 3), () {
        //   voiceClient.disconnect();
        //   // you then still have to update the voice state
        //   print("disconnected!");
        // });

        voiceClient.sendVoiceSelectProtocol(VoiceSelectProtocolBuilder(
          protocol: "webrtc",

          // you can paste the sdp from the browser here for testing, and a session description is returned.
          data: "e",
        ));
      });

      voiceClient.onVoiceSessionDescription.listen((event) {
        print("got session description!");
        print(event.sdp);
      });
    }

    client.onVoiceServerUpdate.listen((event) async {
      // print("GOT VOICE SERVER UPDATE!");

      token = event.token;
      endpoint = event.endpoint;
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

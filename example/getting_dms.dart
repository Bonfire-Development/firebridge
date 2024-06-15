import 'dart:io';

import 'package:firebridge/firebridge.dart';

void main() async {
  String token = Platform.environment['TOKEN']!;
  final client = await Nyxx.connectGateway(
    token,
    GatewayIntents.all,
    options: GatewayClientOptions(plugins: [logging, cliIntegration]),
  );

  client.channels.listDmChannels().then((value) {
    for (var dm in value) {
      print(dm.recipients);
    }
  });
}

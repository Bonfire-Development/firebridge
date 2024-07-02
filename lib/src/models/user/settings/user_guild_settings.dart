import 'package:firebridge/src/utils/to_string_helper/base_impl.dart';

class UserGuildSettings with ToStringHelper {
  int version;
  bool suppressRoles;
  bool suppressEveryone;
  int notifyHighlights;
  bool muted;
  bool muteScheduledEvents;
  dynamic muteConfig;
  bool mobilePush;
  int messageNotifications;
  bool hideMutedChannels;
  String guildId;
  int flags;
  List<dynamic> channelOverrides;

  UserGuildSettings({
    required this.version,
    required this.suppressRoles,
    required this.suppressEveryone,
    required this.notifyHighlights,
    required this.muted,
    required this.muteScheduledEvents,
    required this.muteConfig,
    required this.mobilePush,
    required this.messageNotifications,
    required this.hideMutedChannels,
    required this.guildId,
    required this.flags,
    required this.channelOverrides,
  });
}

import 'package:firebridge/src/models/presence.dart';
import 'package:firebridge/src/models/user/settings/custom_status.dart';
import 'package:firebridge/src/models/user/settings/guild_folder.dart';
import 'package:firebridge/src/utils/to_string_helper/base_impl.dart';

class UserSettings with ToStringHelper {
  bool detectPlatformAccounts;
  int animateStickers;
  bool inlineAttachmentMedia;
  UserStatus status;
  bool messageDisplayCompact;
  bool viewNsfwGuilds;
  int timezoneOffset;
  bool enableTtsCommand;
  bool disableGamesTab;
  bool streamNotificationsEnabled;
  bool animateEmoji;
  List<GuildFolder> guildFolders;
  CustomStatus? customStatus;

  UserSettings({
    required this.detectPlatformAccounts,
    required this.animateStickers,
    required this.inlineAttachmentMedia,
    required this.status,
    required this.messageDisplayCompact,
    required this.viewNsfwGuilds,
    required this.timezoneOffset,
    required this.enableTtsCommand,
    required this.disableGamesTab,
    required this.streamNotificationsEnabled,
    required this.animateEmoji,
    required this.guildFolders,
    this.customStatus,
  });
}

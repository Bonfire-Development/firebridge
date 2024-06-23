import 'package:firebridge/firebridge.dart';
import 'package:firebridge/src/models/guild/guild_member_range.dart';
import 'package:firebridge/src/utils/to_string_helper/to_string_helper.dart';

class GuildSubscription with ToStringHelper {
  final Map<Snowflake, GuildMemberRange> channels;

  GuildSubscription({
    required this.channels,
  });
}

import 'package:firebridge/firebridge.dart';
import 'package:firebridge/src/models/guild/guild_member_range.dart';
import 'package:firebridge/src/utils/to_string_helper/to_string_helper.dart';

class GuildSubscription with ToStringHelper {
  final bool? typing;
  final bool? threads;
  final bool? activities;
  final bool? memberUpdates;
  final List<Snowflake>? members;
  final List<Snowflake>? threadMemberLists;
  final Map<Snowflake, GuildMemberRange> channels;

  GuildSubscription({
    this.typing,
    this.threads,
    this.activities,
    this.members,
    this.memberUpdates,
    this.threadMemberLists,
    required this.channels,
  });
}

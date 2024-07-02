import 'package:firebridge/src/models/channel/channel.dart';
import 'package:firebridge/src/models/snowflake.dart';
import 'package:firebridge/src/utils/to_string_helper/base_impl.dart';

class ReadState with ToStringHelper {
  int mentionCount;
  DateTime lastPinTimestamp;
  PartialChannel id;
  int flags;
  Snowflake? lastMessageId;
  int? lastViewed;

  ReadState({
    required this.mentionCount,
    required this.lastPinTimestamp,
    required this.id,
    required this.flags,
    this.lastMessageId,
    this.lastViewed,
  });
}

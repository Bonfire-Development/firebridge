import 'package:firebridge/src/models/channel/channel.dart';
import 'package:firebridge/src/models/snowflake.dart';
import 'package:firebridge/src/utils/to_string_helper/base_impl.dart';

class ReadState with ToStringHelper {
  int mentionCount;
  DateTime lastPinTimestamp;
  String lastMessageId;
  PartialChannel id;
  int flags;
  int? lastViewed;

  ReadState({
    required this.mentionCount,
    required this.lastPinTimestamp,
    required this.lastMessageId,
    required this.id,
    required this.flags,
    this.lastViewed,
  });
}

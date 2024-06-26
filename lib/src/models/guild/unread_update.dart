import 'package:firebridge/src/models/snowflake.dart';
import 'package:firebridge/src/utils/to_string_helper/base_impl.dart';

class ChannelUnreadUpdate with ToStringHelper {
  final Snowflake id;
  final Snowflake lastMessageId;
  final DateTime? lastPinTimestamp;

  ChannelUnreadUpdate({
    required this.id,
    required this.lastMessageId,
    this.lastPinTimestamp,
  });
}

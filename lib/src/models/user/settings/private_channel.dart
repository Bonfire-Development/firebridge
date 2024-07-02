import 'package:firebridge/firebridge.dart';
import 'package:firebridge/src/utils/to_string_helper/base_impl.dart';

/// Private channel. Used for direct messaging.
class PrivateChannel with ToStringHelper {
  List<dynamic>? safetyWarnings;
  bool? isSpam;
  int type;
  List<User> recipients;
  Snowflake lastMessageId;
  Snowflake id;
  int flags;

  PrivateChannel({
    this.safetyWarnings,
    this.isSpam,
    required this.type,
    required this.recipients,
    required this.lastMessageId,
    required this.id,
    required this.flags,
  });
}

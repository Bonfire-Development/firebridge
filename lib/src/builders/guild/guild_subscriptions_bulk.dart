import 'package:firebridge/firebridge.dart';
import 'package:firebridge/src/models/gateway/events/guild.dart';
import 'package:firebridge/src/models/guild/guild_subscription.dart';

class GuildSubscriptionsBulkBuilder
    extends CreateBuilder<GuildSubscriptionsBulkEvent> {
  Map<Snowflake, GuildSubscription>? subscriptions;

  @override
  Map<String, Object?> build() {
    // 'ids': subscriptions
    Map<int, Map<String, Map<int, List<int>>>?> _subscriptions = {};
    subscriptions?.forEach((guildId, subscription) {
      _subscriptions[guildId.value] = {"channels": {}};
      subscription.channels.forEach((channelId, channelRange) {
        // _subscriptions[guildId.value]!["channels"]![channelId.value] = [
        //   channelRange.lowerMemberBound,
        //   channelRange.upperMemberBound
        // ];
      });
    });
    return {"subscriptions": _subscriptions};
  }
}

import 'package:flutter/foundation.dart';

/// Signals local read/dismiss changes so retained screens update their badges.
class NotificationState {
  static final revision = ValueNotifier<int>(0);
  static void notifyChanged() => revision.value++;
}

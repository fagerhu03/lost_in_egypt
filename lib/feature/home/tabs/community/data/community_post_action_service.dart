import 'package:flutter/foundation.dart';

class CommunityPostActionService {
  static final CommunityPostActionService instance = CommunityPostActionService._internal();

  CommunityPostActionService._internal();

  /// A ValueNotifier that holds the content of a post that should be pre-filled
  /// when the user navigates to the Community Tab.
  final ValueNotifier<String?> pendingPostContent = ValueNotifier<String?>(null);
  
  /// Optional: holds the event ID to tag the post with an event
  String? pendingEventId;
  
  /// Optional: holds the event name to display in the post
  String? pendingEventName;
}

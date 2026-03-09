import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session.dart';

/// Exposes the current user ID from persistent storage (app-wide).
final sessionUserIdProvider = FutureProvider<String?>((ref) {
  return UserSession.userId();
});

// null_id_provider.dart
import 'id_provider.dart';

/// Null ID provider that returns null for all IDs
/// Used as default when no IDs are needed
class NullIdProvider implements IdProvider {
  @override
  Future<void> initialize() async {}

  @override
  void initializeSync() {}

  @override
  String? get deviceId => null;

  @override
  String? get sessionId => null;

  @override
  bool get isInitialized => true;

  @override
  void regenerateSessionId() {}

  @override
  void reset() {}

  @override
  void resetSession() {}
}
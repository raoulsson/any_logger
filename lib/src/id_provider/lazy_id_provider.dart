import '../../any_logger.dart';
import 'id_provider.dart';

class LazyIdProvider implements IdProvider {
  final IdProvider _delegate;
  bool _lazyInitialized = false;

  // Store any initialization error to rethrow later
  dynamic _initError;

  LazyIdProvider(this._delegate);

  void _ensureInitialized() {
    // Skip initialization for NullIdProvider
    if (_delegate is NullIdProvider) {
      _lazyInitialized = true;
      return;
    }

    if (_initError != null) {
      throw _initError;
    }

    if (!_lazyInitialized) {
      try {
        _delegate.initializeSync();
        _lazyInitialized = true;
      } catch (e) {
        _initError = e;
        throw e;
      }
    }
  }

  Future<void> _ensureInitializedAsync() async {
    // Skip initialization for NullIdProvider
    if (_delegate is NullIdProvider) {
      _lazyInitialized = true;
      return;
    }

    if (_initError != null) {
      throw _initError;
    }

    if (!_lazyInitialized) {
      try {
        await _delegate.initialize();
        _lazyInitialized = true;
      } catch (e) {
        _initError = e;
        throw e;
      }
    }
  }


  @override
  Future<void> initialize() async {
    await _ensureInitializedAsync();
  }

  @override
  void initializeSync() {
    _ensureInitialized();
  }

  @override
  String? get deviceId {
    if (_initError != null) return null; // Return null if init failed
    try {
      _ensureInitialized();
      return _delegate.deviceId;
    } catch (e) {
      return null; // Return null on error
    }
  }

  @override
  String? get sessionId {
    if (_initError != null) return null; // Return null if init failed
    try {
      _ensureInitialized();
      return _delegate.sessionId;
    } catch (e) {
      return null; // Return null on error
    }
  }

  @override
  void regenerateSessionId() {
    if (_initError == null) {
      try {
        _ensureInitialized();
        _delegate.regenerateSessionId();
      } catch (e) {
        // Ignore
      }
    }
  }

  @override
  void reset() {
    _delegate.reset();
    _lazyInitialized = false;
    _initError = null;
  }

  @override
  void resetSession() {
    _delegate.resetSession();
  }

  @override
  bool get isInitialized => _lazyInitialized && _delegate.isInitialized;
}

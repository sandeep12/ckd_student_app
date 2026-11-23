import 'package:flutter/foundation.dart';

/// API environment configuration.
abstract final class ApiConfig {
  /// Override at build time:
  /// `flutter run --dart-define=API_BASE_URL=https://api.example.com`
  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    // Android emulators reach the host machine via 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3001';
    }
    return 'http://localhost:3001';
  }
}

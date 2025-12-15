import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    const hostEnv = String.fromEnvironment('API_HOST', defaultValue: 'localhost');
    const portEnv = String.fromEnvironment('API_PORT', defaultValue: '5000');

    String resolvedHost = hostEnv;

    // On Android emulators, 'localhost' points to the emulator.
    // Use 10.0.2.2 to reach the host machine.
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android) &&
        (hostEnv == 'localhost' || hostEnv == '127.0.0.1')) {
      resolvedHost = '10.0.2.2';
    }

    return 'http://$resolvedHost:$portEnv/api';
  }
}

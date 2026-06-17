import 'dart:io';

import 'package:flutter/foundation.dart';

class BackendConfig {
  static String get baseUrl {
    const env = String.fromEnvironment('TINYTRAIL_API_BASE');
    if (env.isNotEmpty) return env;

    // Android emulator talks to host via 10.0.2.2.
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api';
    }

    return 'http://localhost:8080/api';
  }

  static String get hygieneBaseUrl {
    const env = String.fromEnvironment('TINYTRAIL_HYGIENE_BASE');
    if (env.isNotEmpty) return env;

    final apiBase = Uri.parse(baseUrl);
    final port = apiBase.port == 8080 ? 8000 : (apiBase.hasPort ? apiBase.port : 8000);
    final scheme = apiBase.scheme.isNotEmpty ? apiBase.scheme : 'http';
    final host = apiBase.host.isNotEmpty ? apiBase.host : 'localhost';

    return Uri(
      scheme: scheme,
      host: host,
      port: port,
    ).toString();
  }
}


import 'package:flutter/foundation.dart';

enum EnvironmentType {
  staging,
  production,
}

class EnvironmentConfig {
  // ignore: constant_identifier_names
  static const String PRODUCTION = "production";
  // ignore: constant_identifier_names
  static const String STAGING = "staging";
  // ignore: constant_identifier_names

  static const String _type = String.fromEnvironment('APIType',
      defaultValue: kDebugMode ? STAGING : PRODUCTION);

  static EnvironmentType get type {
    switch (_type) {
      case PRODUCTION:
        return EnvironmentType.production;

      case STAGING:
        return EnvironmentType.staging;
      default:
        return kDebugMode
            ? EnvironmentType.staging
            : EnvironmentType.production;
    }
  }

  static T when<T>({
    required T production,
    required T staging,
  }) {
    switch (type) {
      case EnvironmentType.production:
        return production;
      case EnvironmentType.staging:
        return staging;
    }
  }
}

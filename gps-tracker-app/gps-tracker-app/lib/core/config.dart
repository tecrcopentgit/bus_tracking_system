/// Backend root URL (no trailing slash, no /api/v1).
///
/// Override at build/run time:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
///
/// Default 10.0.2.2 is the Android emulator's alias for the host machine.
/// (iOS simulator: use http://localhost:8000.)
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

/// How often the latest vehicle location is re-fetched while Home is visible.
const Duration locationPollInterval = Duration(seconds: 5);

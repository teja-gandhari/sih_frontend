class AppConstants {
  static const String devAndroidUrl = 'http://10.0.2.2:8000';
  static const String devWebUrl = 'http://127.0.0.1:8000';
  static const String prodUrl = 'https://api.ruralbiz.ai'; // Example

  static String get baseUrl {
    // Basic logic for selecting baseUrl based on platform/mode
    // For now, default to local dev based on generic platform check
    final base = const bool.fromEnvironment('dart.library.html')
        ? devWebUrl
        : devAndroidUrl;
    return '$base/api/v1';
  }

  static const int apiTimeoutSeconds = 30;
  static const List<String> supportedLanguages = ['en', 'te', 'hi'];
}

class ApiConfig {
  // Use 'http://localhost/gest_absence_api' for Flutter Web
  // Use 'http://10.0.2.2/gest_absence_api' for Android Emulator
  static const String baseUrl = 'http://localhost/gest_absence_api';
  
  static const Map<String, String> headers = {
    'Content-Type': 'application/json; charset=UTF-8',
  };
}
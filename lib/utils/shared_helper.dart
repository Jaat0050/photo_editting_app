import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static late SharedPreferences _preferences;

  static Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static int getCounter() {
    return _preferences.getInt('counter') ?? 0;
  }

  static Future<void> incrementCounter() async {
    int currentCounter = getCounter();
    await _preferences.setInt('counter', currentCounter + 1);
  }

  static Future<void> clearCounter() async {
    await _preferences.remove('counter');
  }
}

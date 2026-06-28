import 'package:marktag/src/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service for storing and retrieving key-value data
/// using shared_preferences.
class StorageService {
  /// Creates a [StorageService] with an optional [SharedPreferences] instance
  /// for testability.
  StorageService({SharedPreferences? sharedPreferences, LoggerService? logger})
    : _logger = logger ?? LoggerService(name: 'StorageService'),
      _sharedPreferencesFuture = sharedPreferences != null
          ? Future.value(sharedPreferences)
          : SharedPreferences.getInstance();

  final LoggerService _logger;
  final Future<SharedPreferences> _sharedPreferencesFuture;

  /// Stores a string value for the given [key].
  ///
  /// Returns `true` if the value was successfully stored.
  Future<bool> setString(String key, String value) async {
    final prefs = await _sharedPreferencesFuture;
    final result = await prefs.setString(key, value);
    _logger.debugLog('setString: key=$key, value=$value, result=$result');
    return result;
  }

  /// Retrieves a string value for the given [key].
  ///
  /// Returns the value if it exists, or `null` otherwise.
  Future<String?> getString(String key) async {
    final prefs = await _sharedPreferencesFuture;
    final value = prefs.getString(key);
    _logger.debugLog('getString: key=$key, value=$value');
    return value;
  }

  /// Removes the value for the given [key].
  ///
  /// Returns `true` if the value was successfully removed.
  Future<bool> remove(String key) async {
    final prefs = await _sharedPreferencesFuture;
    final result = await prefs.remove(key);
    _logger.debugLog('remove: key=$key, result=$result');
    return result;
  }

  /// Clears all stored values.
  ///
  /// Returns `true` if all values were successfully cleared.
  Future<bool> clear() async {
    final prefs = await _sharedPreferencesFuture;
    final result = await prefs.clear();
    _logger.debugLog('clear: result=$result');
    return result;
  }
}

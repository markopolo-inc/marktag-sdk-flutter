import 'dart:convert';
import 'package:marktag/src/models/user.dart';
import 'package:marktag/src/services/logger_service.dart';
import 'package:marktag/src/services/storage_service.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

/// A service for managing the current user in the Marktag system.
///
/// Provides methods to get and set the user, 
/// persisting data using [StorageService].
class UserService {
  /// Creates a [UserService] instance.
  ///
  /// [storageService] and [logger] can be injected for testability.
  UserService({
    StorageService? storageService,
    LoggerService? logger,
    Uuid? uuidGenerator,
  })  : _storageService = storageService ?? StorageService(),
        _logger = logger ?? LoggerService(name: 'UserService'),
        _uuid = uuidGenerator ?? const Uuid();

  static const String _userKey = 'mt_user';
  final StorageService _storageService;
  final LoggerService _logger;
  final Uuid _uuid;

  static User? _user;

  /// Test-only getter for the cached user. Use only in tests.
  @visibleForTesting
  static User? get testUser => _user;

  /// Test-only setter for the cached user. Use only in tests.
  @visibleForTesting
  static set testUser(User? user) => _user = user;

  /// Test-only method to clear the cached user. Use only in tests.
  @visibleForTesting
  static void clearCache() => _user = null;

  /// Returns the current user, loading from storage if necessary.
  ///
  /// If no user is found, a new user is created with a generated muid.
  /// Throws and logs any error encountered.
  Future<User> getUser() async {
    try {
      if (_user != null) {
        return _user!;
      }
      final userStr = await _storageService.getString(_userKey);
      _logger.debugLog('User from storage: $userStr');
      if (userStr != null) {
        final loadedUser = User.fromJson(_decodeJson(userStr));
        _user = loadedUser;
        return loadedUser;
      } else {
        final newUser = User(muid: _uuid.v4());
        await _storageService.setString(
          _userKey,
          _encodeJson(newUser.toJson()),
        );
        _user = newUser;
        return newUser;
      }
    } catch (error, stack) {
      _logger.debugLog(
        'Error in getUser: $error',
        error: error,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Sets the current user's [email] and [phone], updating storage.
  ///
  /// If no user exists, a new one is created with a generated muid.
  /// Throws and logs any error encountered.
  Future<void> setUser({String? email, String? phone}) async {
    try {
      final userStr = await _storageService.getString(_userKey);
      User updatedUser;
      if (userStr != null) {
        final existing = User.fromJson(_decodeJson(userStr));
        updatedUser = User(muid: existing.muid, email: email, phone: phone);
      } else {
        updatedUser = User(muid: _uuid.v4(), email: email, phone: phone);
      }
      await _storageService.setString(
        _userKey,
        _encodeJson(updatedUser.toJson()),
      );
      _user = updatedUser;
      _logger.debugLog('User updated: \x1B[32m$updatedUser\x1B[0m');
    } catch (error, stack) {
      _logger.debugLog(
        'Error in setUser: $error',
        error: error,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Decodes a JSON string to a Map.
  Map<String, dynamic> _decodeJson(String jsonStr) {
    final dynamic decoded = json.decode(jsonStr);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    } else if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    } else {
      throw const FormatException('Decoded JSON is not a Map');
    }
  }

  /// Encodes a Map to a JSON string, omitting null values.
  String _encodeJson(Map<String, dynamic> map) {
    map.removeWhere((key, value) => value == null);
    return json.encode(map);
  }
}

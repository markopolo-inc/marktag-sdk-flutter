import 'package:meta/meta.dart';

/// Represents a user in the Marktag system.
///
/// [muid] is the Marktag user ID and is required.
/// [email] and [phone] are optional fields.
@immutable
class User {
  /// Creates a [User] instance.
  ///
  /// [muid] is required. [email] and [phone] are optional.
  const User({
    required this.muid,
    this.email,
    this.phone,
  });

  /// Creates a [User] from a JSON map.
  ///
  /// Throws [FormatException] if required fields are missing or invalid.
  factory User.fromJson(Map<String, dynamic> json) {
    if (json['muid'] == null || json['muid'] is! String) {
      throw const FormatException('Missing or invalid muid');
    }
    return User(
      muid: json['muid'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  /// The Marktag user ID (required).
  final String muid;

  /// The user's email address (optional).
  final String? email;

  /// The user's phone number (optional).
  final String? phone;

  /// Returns a string representation of the user.
  @override
  String toString() => 'User(muid: $muid, email: $email, phone: $phone)';

  /// Converts this [User] instance to a JSON map.
  ///
  /// Omits null fields from the resulting map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'muid': muid};
    if (email != null) map['email'] = email;
    if (phone != null) map['phone'] = phone;
    return map;
  }

  @override
  bool operator ==(Object other) {
    if (other is! User) return false;
    return muid == other.muid && email == other.email && phone == other.phone;
  }

  @override
  int get hashCode => Object.hash(muid, email, phone);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktag/src/models/user.dart';

void main() {
  group('User', () {
    test('can be constructed with only required field', () {
      const user = User(muid: 'abc123');
      expect(user.muid, 'abc123');
      expect(user.email, isNull);
      expect(user.phone, isNull);
    });

    test('can be constructed with all fields', () {
      const user =
          User(muid: 'abc123', email: 'test@example.com', phone: '12345');
      expect(user.muid, 'abc123');
      expect(user.email, 'test@example.com');
      expect(user.phone, '12345');
    });

    test('supports value equality', () {
      const user1 = User(muid: 'abc123', email: 'a@b.com', phone: '123');
      const user2 = User(muid: 'abc123', email: 'a@b.com', phone: '123');
      const user3 = User(muid: 'abc123', email: 'a@b.com');
      expect(user1, user2);
      expect(user1 == user3, isFalse);
    });

    test('toString returns expected format', () {
      const user = User(muid: 'abc123', email: 'a@b.com', phone: '123');
      expect(user.toString(), 'User(muid: abc123, email: a@b.com, phone: 123)');
    });

    test('fromJson creates User from valid JSON', () {
      final json = {'muid': 'abc123', 'email': 'a@b.com', 'phone': '123'};
      final user = User.fromJson(json);
      expect(user.muid, 'abc123');
      expect(user.email, 'a@b.com');
      expect(user.phone, '123');
    });

    test('fromJson throws if muid is missing', () {
      final json = {'email': 'a@b.com'};
      expect(() => User.fromJson(json), throwsFormatException);
    });

    test('fromJson throws if muid is not a string', () {
      final json = {'muid': 123};
      expect(() => User.fromJson(json), throwsFormatException);
    });

    test('toJson omits null fields', () {
      const user = User(muid: 'abc123');
      final json = user.toJson();
      expect(json, {'muid': 'abc123'});
    });

    test('toJson includes all non-null fields', () {
      const user = User(muid: 'abc123', email: 'a@b.com', phone: '123');
      final json = user.toJson();
      expect(json, {'muid': 'abc123', 'email': 'a@b.com', 'phone': '123'});
    });

    test('fromJson and toJson round-trip', () {
      const user = User(muid: 'abc123', email: 'a@b.com', phone: '123');
      final json = user.toJson();
      final user2 = User.fromJson(json);
      expect(user2, user);
    });
  });
}

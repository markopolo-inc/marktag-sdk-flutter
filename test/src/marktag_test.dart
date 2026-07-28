import 'package:flutter_test/flutter_test.dart';
import 'package:marktag/marktag.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Marktag', () {
    test('can be instantiated', () {
      expect(Marktag.instance, isNotNull);
    });

    test('calling init() twice does not re-run initialization', () {
      final marktag = Marktag.instance
        ..init(tag: 'mtag.example.com', tagId: 'abc123');
      expect(marktag.isInitializedForTest, isTrue);
      expect(marktag.tagForTest, 'mtag.example.com');

      // A second call — even with different config — is ignored entirely.
      marktag.init(tag: 'other.example.com', tagId: 'xyz789');
      expect(marktag.tagForTest, 'mtag.example.com');
    });
  });
}

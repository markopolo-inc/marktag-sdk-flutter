import 'package:flutter_test/flutter_test.dart';
import 'package:marktag/marktag.dart';

void main() {
  group('Marktag', () {
    test('can be instantiated', () {
      expect(Marktag.instance, isNotNull);
    });
  });
}

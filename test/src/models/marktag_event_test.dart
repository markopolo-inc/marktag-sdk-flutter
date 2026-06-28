import 'package:flutter_test/flutter_test.dart';
import 'package:marktag/src/models/marktag_event.dart';

void main() {
  group('MarktagEventItem', () {
    test('fromJson and toJson work correctly', () {
      final json = {
        'id': '123',
        'name': 'Shirt',
        'category': "Apparel, Men's Clothing",
        'variant': 'Blue',
        'quantity': 5,
        'price': 7.59,
        'description': 'A blue shirt',
        'coupon': 'DISCOUNT5',
        'discount': 5.0,
      };
      final item = MarktagEventItem.fromJson(json);
      expect(item.id, '123');
      expect(item.name, 'Shirt');
      expect(item.category, "Apparel, Men's Clothing");
      expect(item.variant, 'Blue');
      expect(item.quantity, 5);
      expect(item.price, 7.59);
      expect(item.description, 'A blue shirt');
      expect(item.coupon, 'DISCOUNT5');
      expect(item.discount, 5.0);
      expect(item.toJson(), json);
    });

    test('fromJson handles integer values for price and discount', () {
      final json = {
        'id': '123',
        'price': 8,
        'discount': 2,
      };
      final item = MarktagEventItem.fromJson(json);
      expect(item.price, 8.0);
      expect(item.price, isA<double>());
      expect(item.discount, 2.0);
      expect(item.discount, isA<double>());
    });

    test('copyWith returns a new instance with updated values', () {
      const item = MarktagEventItem(
        id: '1',
        name: 'Shirt',
        price: 10,
      );
      final updated = item.copyWith(name: 'Pants', price: 20);
      expect(updated.id, '1');
      expect(updated.name, 'Pants');
      expect(updated.price, 20.0);
      expect(updated, isNot(same(item)));
    });

    test('copyWith preserves original values when null is passed', () {
      const item = MarktagEventItem(
        id: '1',
        name: 'Shirt',
        price: 10,
      );
      final updated = item.copyWith();
      expect(updated.id, '1');
      expect(updated.name, 'Shirt');
      expect(updated.price, 10.0);
      expect(updated, isNot(same(item)));
    });
  });

  group('MarktagEvent', () {
    test('fromJson and toJson work correctly', () {
      final json = {
        'event': 'Purchase',
        'event_source': 'web',
        'pageUrl': 'https://example.com',
        'email': 'test@example.com',
        'phone': '1234567890',
        'mt_ref_src': 'ref123',
        'items': [
          {
            'id': '123',
            'name': 'Shirt',
            'category': 'Apparel',
            'variant': 'Blue',
            'quantity': 2,
            'price': 15.0,
            'description': 'A blue shirt',
            'coupon': 'COUPON',
            'discount': 3.0,
          },
        ],
        'metadata': {'foo': 'bar', 'baz': 1},
      };
      final event = MarktagEvent.fromJson(json);
      expect(event.event, 'Purchase');
      expect(event.eventSource, 'web');
      expect(event.pageUrl, 'https://example.com');
      expect(event.email, 'test@example.com');
      expect(event.phone, '1234567890');
      expect(event.mtRefSrc, 'ref123');
      expect(event.items, isNotNull);
      expect(event.items!.first.name, 'Shirt');
      expect(event.metadata, {'foo': 'bar', 'baz': 1});
      expect(event.toJson(), json);
    });

    test('copyWith returns a new instance with updated values', () {
      final event = MarktagEvent(
        event: 'AddToCart',
      );
      final updated = event.copyWith(
        event: 'Purchase',
        email: 'test@example.com',
      );
      expect(updated.event, 'Purchase');
      expect(updated.pageUrl, isNull);
      expect(updated.email, 'test@example.com');
      expect(updated, isNot(same(event)));
    });

    test('copyWith preserves original values when null is passed', () {
      final event = MarktagEvent(
        event: 'AddToCart',
        email: 'original@example.com',
      );
      final updated = event.copyWith();
      expect(updated.event, 'AddToCart');
      expect(updated.email, 'original@example.com');
      expect(updated, isNot(same(event)));
    });

    test('rejects snake_case event names', () {
      expect(
        () => MarktagEvent(event: 'add_to_cart'),
        throwsArgumentError,
      );
    });

    test('rejects camelCase event names', () {
      expect(
        () => MarktagEvent(event: 'addToCart'),
        throwsArgumentError,
      );
    });

    test('handles null pageUrl in JSON', () {
      final json = {
        'event': 'ViewContent',
        // pageUrl is omitted
      };
      final event = MarktagEvent.fromJson(json);
      expect(event.pageUrl, isNull);
      expect(event.event, 'ViewContent');
      expect(event.toJson(), {'event': 'ViewContent'});
    });
  });
}

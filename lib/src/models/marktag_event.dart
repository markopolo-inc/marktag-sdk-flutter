/// Represents an item involved in a Marktag event, 
/// such as a product in a cart or purchase.
class MarktagEventItem {
  /// Creates a [MarktagEventItem].
  const MarktagEventItem({
    this.id,
    this.name,
    this.category,
    this.variant,
    this.quantity,
    this.price,
    this.description,
    this.coupon,
    this.discount,
  });

  /// Creates a [MarktagEventItem] from a JSON map.
  factory MarktagEventItem.fromJson(Map<String, dynamic> json) {
    return MarktagEventItem(
      id: json['id'] as String?,
      name: json['name'] as String?,
      category: json['category'] as String?,
      variant: json['variant'] as String?,
      quantity: json['quantity'] as int?,
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : json['price'] as double?,
      description: json['description'] as String?,
      coupon: json['coupon'] as String?,
      discount: (json['discount'] is int)
          ? (json['discount'] as int).toDouble()
          : json['discount'] as double?,
    );
  }

  /// Unique id of product
  final String? id;

  /// Product Name eg. "Shirt"
  final String? name;

  /// Product Category, e.g., "Apparel" or "Apparel, Men's Clothing"
  final String? category;

  /// Product's variant, e.g., "Blue"
  final String? variant;

  /// Quantity of this product added to cart or purchased, e.g., 5
  final int? quantity;

  /// Price of the Product, e.g., 7.59
  final double? price;

  /// Description of the Product
  final String? description;

  /// Any coupon used through checkout
  final String? coupon;

  /// Any monetary discount added to the product
  /// e.g., if 5 USD discount is added, discount value should be 5.00.
  /// If any percentage discount is added, 
  /// you need to convert the percentage to monetary value
  final double? discount;

  /// Converts this [MarktagEventItem] to a JSON map.
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (name != null) 'name': name,
        if (category != null) 'category': category,
        if (variant != null) 'variant': variant,
        if (quantity != null) 'quantity': quantity,
        if (price != null) 'price': price,
        if (description != null) 'description': description,
        if (coupon != null) 'coupon': coupon,
        if (discount != null) 'discount': discount,
      };

  /// Returns a copy of this item with the given fields 
  /// replaced with new values.
  MarktagEventItem copyWith({
    String? id,
    String? name,
    String? category,
    String? variant,
    int? quantity,
    double? price,
    String? description,
    String? coupon,
    double? discount,
  }) {
    return MarktagEventItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      variant: variant ?? this.variant,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      description: description ?? this.description,
      coupon: coupon ?? this.coupon,
      discount: discount ?? this.discount,
    );
  }
}

/// Represents a Marktag event, such as a page view, add to cart, or purchase.
class MarktagEvent {
  static final RegExp _pascalCaseEventName = RegExp(r'^[A-Z][a-zA-Z0-9]*$');

  /// Throws [ArgumentError] if [name] is not PascalCase (e.g. `AddToCart`).
  static void assertPascalCaseEventName(String name) {
    if (!_pascalCaseEventName.hasMatch(name)) {
      throw ArgumentError.value(
        name,
        'event',
        'Event name must be PascalCase (e.g. AddToCart). '
        'Use MarktagEvents constants instead of snake_case or camelCase.',
      );
    }
  }

  /// Creates a [MarktagEvent].
  factory MarktagEvent({
    required String event,
    String? pageUrl,
    String? eventSource,
    String? email,
    String? phone,
    String? mtRefSrc,
    List<MarktagEventItem>? items,
    Map<String, dynamic>? metadata,
  }) {
    assertPascalCaseEventName(event);
    return MarktagEvent._(
      event: event,
      pageUrl: pageUrl,
      eventSource: eventSource,
      email: email,
      phone: phone,
      mtRefSrc: mtRefSrc,
      items: items,
      metadata: metadata,
    );
  }

  const MarktagEvent._({
    required this.event,
    this.pageUrl,
    this.eventSource,
    this.email,
    this.phone,
    this.mtRefSrc,
    this.items,
    this.metadata,
  });

  /// Creates a [MarktagEvent] from a JSON map.
  factory MarktagEvent.fromJson(Map<String, dynamic> json) {
    final event = json['event'] as String;
    assertPascalCaseEventName(event);
    return MarktagEvent._(
      event: event,
      eventSource: json['event_source'] as String?,
      pageUrl: json['pageUrl'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      mtRefSrc: json['mt_ref_src'] as String?,
      items: (json['items'] as List?)
          ?.map((e) => MarktagEventItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  /// The name of the event.
  final String event;

  /// The source of the event (optional).
  final String? eventSource;

  /// The URL of the page where the event occurred.
  final String? pageUrl;

  /// The email associated with the event (optional).
  final String? email;

  /// The phone number associated with the event (optional).
  final String? phone;

  /// The Marktag reference source (optional).
  final String? mtRefSrc;

  /// The list of items involved in the event (optional).
  final List<MarktagEventItem>? items;

  /// Additional metadata for the event (optional).
  final Map<String, dynamic>? metadata;

  /// Converts this [MarktagEvent] to a JSON map.
  Map<String, dynamic> toJson() => {
        'event': event,
        if (eventSource != null) 'event_source': eventSource,
        if (pageUrl != null) 'pageUrl': pageUrl,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (mtRefSrc != null) 'mt_ref_src': mtRefSrc,
        if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
        if (metadata != null) 'metadata': metadata,
      };

  /// Returns a copy of this event with the given fields 
  /// replaced with new values.
  MarktagEvent copyWith({
    String? event,
    String? eventSource,
    String? pageUrl,
    String? email,
    String? phone,
    String? mtRefSrc,
    List<MarktagEventItem>? items,
    Map<String, dynamic>? metadata,
  }) {
    final nextEvent = event ?? this.event;
    if (event != null) {
      assertPascalCaseEventName(nextEvent);
    }
    return MarktagEvent._(
      event: nextEvent,
      eventSource: eventSource ?? this.eventSource,
      pageUrl: pageUrl ?? this.pageUrl,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      mtRefSrc: mtRefSrc ?? this.mtRefSrc,
      items: items ?? this.items,
      metadata: metadata ?? this.metadata,
    );
  }
}

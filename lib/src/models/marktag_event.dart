/// Represents an item involved in a MarkTag event, 
/// such as a product in a cart or purchase.
class MarkTagEventItem {
  /// Creates a [MarkTagEventItem].
  const MarkTagEventItem({
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

  /// Creates a [MarkTagEventItem] from a JSON map.
  factory MarkTagEventItem.fromJson(Map<String, dynamic> json) {
    return MarkTagEventItem(
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

  /// Converts this [MarkTagEventItem] to a JSON map.
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
  MarkTagEventItem copyWith({
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
    return MarkTagEventItem(
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

/// Represents a MarkTag event, such as a page view, add to cart, or purchase.
class MarkTagEvent {
  /// Creates a [MarkTagEvent].
  const MarkTagEvent({
    required this.event,
    this.pageUrl,
    this.eventSource,
    this.email,
    this.phone,
    this.mtRefSrc,
    this.items,
    this.metadata,
  });

  /// Creates a [MarkTagEvent] from a JSON map.
  factory MarkTagEvent.fromJson(Map<String, dynamic> json) {
    return MarkTagEvent(
      event: json['event'] as String,
      eventSource: json['event_source'] as String?,
      pageUrl: json['page_url'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      mtRefSrc: json['mt_ref_src'] as String?,
      items: (json['items'] as List?)
          ?.map((e) => MarkTagEventItem.fromJson(e as Map<String, dynamic>))
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

  /// The MarkTag reference source (optional).
  final String? mtRefSrc;

  /// The list of items involved in the event (optional).
  final List<MarkTagEventItem>? items;

  /// Additional metadata for the event (optional).
  final Map<String, dynamic>? metadata;

  /// Converts this [MarkTagEvent] to a JSON map.
  Map<String, dynamic> toJson() => {
        'event': event,
        if (eventSource != null) 'event_source': eventSource,
        if (pageUrl != null) 'page_url': pageUrl,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (mtRefSrc != null) 'mt_ref_src': mtRefSrc,
        if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
        if (metadata != null) 'metadata': metadata,
      };

  /// Returns a copy of this event with the given fields 
  /// replaced with new values.
  MarkTagEvent copyWith({
    String? event,
    String? eventSource,
    String? pageUrl,
    String? email,
    String? phone,
    String? mtRefSrc,
    List<MarkTagEventItem>? items,
    Map<String, dynamic>? metadata,
  }) {
    return MarkTagEvent(
      event: event ?? this.event,
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

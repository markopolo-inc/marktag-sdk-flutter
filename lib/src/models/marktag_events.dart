/// Standard Marktag event names (PascalCase).
abstract final class MarktagEvents {
  /// Payment info added during checkout.
  static const String addPaymentInfo = 'AddPaymentInfo';

  /// Product added to cart.
  static const String addToCart = 'AddToCart';

  /// Product added to wishlist.
  static const String addToWishlist = 'AddToWishlist';

  /// Checkout flow started.
  static const String beginCheckout = 'BeginCheckout';

  /// Checkout initiated.
  static const String initiateCheckout = 'InitiateCheckout';

  /// User logged in.
  static const String login = 'Login';

  /// Page viewed.
  static const String pageView = 'PageView';

  /// Purchase completed.
  static const String purchase = 'Purchase';

  /// Refund issued.
  static const String refund = 'Refund';

  /// Product removed from cart.
  static const String removeFromCart = 'RemoveFromCart';

  /// Search performed.
  static const String search = 'Search';

  /// Content shared.
  static const String share = 'Share';

  /// User signed up.
  static const String signup = 'Signup';

  /// Cart viewed.
  static const String viewCart = 'ViewCart';

  /// Content viewed.
  static const String viewContent = 'ViewContent';

  /// Item viewed.
  static const String viewItem = 'ViewItem';
}

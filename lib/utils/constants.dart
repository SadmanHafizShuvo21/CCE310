class AppConstants {
  static const String appName = 'FreshGrocer';
  static const String appVersion = '1.0.0';

  // API endpoints
  static const String baseUrl = 'https://your-api-url.com/api';
  static const String productsEndpoint = '/products';
  static const String categoriesEndpoint = '/categories';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String ordersEndpoint = '/orders';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String cartItemsKey = 'cart_items';

  // App colors
  static const primaryColor = 0xFF4CAF50;
  static const secondaryColor = 0xFFFF9800;
  static const backgroundColor = 0xFFF5F5F5;
  static const textColor = 0xFF333333;
  static const errorColor = 0xFFD32F2F;
}

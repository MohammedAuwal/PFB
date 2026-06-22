// lib/config/routes/route_names.dart
class RouteNames {
  RouteNames._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String splash    = '/';
  static const String login     = '/login';
  static const String signup    = '/signup';

  // ── Customer Shell ────────────────────────────────────────────────────────
  static const String mainShell     = '/shell';
  static const String home          = '/home';
  static const String cart          = '/cart';
  static const String orders        = '/orders';
  static const String profile       = '/profile';
  static const String favorites     = '/favorites';
  static const String notifications = '/notifications';

  // ── Redirect helpers (existing — do NOT remove) ───────────────────────────
  static const String redirectCart    = '/redirect/cart';
  static const String redirectProfile = '/redirect/profile';

  // ── Admin ─────────────────────────────────────────────────────────────────
  static const String admin       = '/admin';
  static const String addProduct  = '/admin/add-product';
  static const String adminOrders = '/admin/orders';

  // ── POS Terminal ──────────────────────────────────────────────────────────
  static const String posDashboard = '/pos';
  static const String posReceipt   = '/pos/receipt';
}
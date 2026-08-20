/// Application-wide constants and configurations
class AppConstants {
  AppConstants._();

  static const String appTitle = "Rice URL Shortener & QR Studio";
  static const String defaultDomain = "link.thejambers.com";
  static const String riceDomain = "rice.edu";
  static const String defaultFallbackUrl = "https://rice.edu";
  static const String allowedAuthDomain = "rice.edu";

  // Code generation parameters
  static const int defaultCodeLength = 5;
  static const String allowedSlugRegex = r"^[a-zA-Z0-9_-]{3,30}$";

  // Reserved keywords to prevent collision with application routes & APIs
  static const Set<String> reservedRoutes = {
    "app",
    "api",
    "login",
    "auth",
    "dashboard",
    "static",
    "r",
    "admin",
    "assets",
    "favicon",
    "manifest",
    "null",
    "undefined",
    "help",
    "about",
    "settings",
  };

  // QR resolution options (pixels)
  static const List<int> qrDownloadSizes = [128, 256, 512, 1024, 2048];
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/rice_theme.dart';
import 'data/services/auth_service.dart';
import 'data/services/link_service.dart';
import 'data/services/serverpod_link_service.dart';
import 'presentation/state/auth_controller.dart';
import 'presentation/state/link_controller.dart';
import 'presentation/views/auth_view.dart';
import 'presentation/views/dashboard_view.dart';
import 'presentation/views/not_found_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Active Link Backend: AWS Serverpod Container
  const backendUrlEnv = String.fromEnvironment('BACKEND_URL', defaultValue: '');
  final backendUrl = backendUrlEnv.isNotEmpty
      ? backendUrlEnv
      : (kIsWeb && Uri.base.host.isNotEmpty && Uri.base.host != 'localhost' && Uri.base.host != '127.0.0.1'
          ? Uri.base.origin
          : 'http://localhost:8081');

  final authService = AuthService();
  final LinkService linkService = ServerpodLinkService(backendUrl: backendUrl);

  final authController = AuthController(authService: authService);
  final linkController = LinkController(linkService: linkService);

  runApp(RiceUrlShortenerApp(
    authController: authController,
    linkController: linkController,
  ));
}

class RiceUrlShortenerApp extends StatefulWidget {
  final AuthController authController;
  final LinkController linkController;

  const RiceUrlShortenerApp({
    super.key,
    required this.authController,
    required this.linkController,
  });

  @override
  State<RiceUrlShortenerApp> createState() => _RiceUrlShortenerAppState();
}

class _RiceUrlShortenerAppState extends State<RiceUrlShortenerApp> {
  @override
  void initState() {
    super.initState();
    widget.authController.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    final user = widget.authController.currentUser;
    if (user != null) {
      widget.linkController.init(user.uid);
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.authController.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: RiceTheme.lightTheme,
      home: widget.authController.isAuthenticated
          ? DashboardView(
              authController: widget.authController,
              linkController: widget.linkController,
            )
          : AuthView(authController: widget.authController),
      onGenerateRoute: (settings) {
        if (settings.name == "/" || settings.name == "/app" || settings.name == "/dashboard") {
          return MaterialPageRoute(
            builder: (_) => widget.authController.isAuthenticated
                ? DashboardView(
                    authController: widget.authController,
                    linkController: widget.linkController,
                  )
                : AuthView(authController: widget.authController),
          );
        }

        final path = settings.name?.replaceFirst("/", "") ?? "";
        return MaterialPageRoute(
          builder: (_) => NotFoundView(code: path),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/rice_theme.dart';
import 'data/services/auth_service.dart';
import 'data/services/firestore_link_service.dart';
import 'presentation/state/auth_controller.dart';
import 'presentation/state/link_controller.dart';
import 'presentation/views/auth_view.dart';
import 'presentation/views/dashboard_view.dart';
import 'presentation/views/not_found_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  FirebaseAuth? firebaseAuth;
  FirebaseFirestore? firestore;

  try {
    if (!DefaultFirebaseOptions.isPlaceholderConfig) {
      // Initialize Firebase with platform-specific options
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseAuth = FirebaseAuth.instance;
      firestore = FirebaseFirestore.instance;
    } else {
      debugPrint("Dev mode: Running with mock data and auth bypass.");
    }
  } catch (e) {
    debugPrint("Firebase initialized in mock/standalone mode: $e");
  }

  final authService = AuthService(firebaseAuth: firebaseAuth);
  final linkService = FirestoreLinkService(firestore: firestore);

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

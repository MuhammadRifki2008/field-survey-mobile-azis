import 'package:field_survey/routes/app_routes.dart';
import 'package:field_survey/screens/splash/splash_screen.dart';
import 'package:go_router/go_router.dart';

class AppPages {
  static final router = GoRouter(
    initialLocation:AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      )
    ]
  );
}
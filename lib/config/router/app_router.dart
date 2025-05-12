import 'package:go_router/go_router.dart';
import '/presentations/screens/screen.dart';
import '/presentations/screens/iniciar/login.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
  ]
);
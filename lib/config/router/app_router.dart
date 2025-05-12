import 'package:go_router/go_router.dart';
import '/presentations/screens/screen.dart';

final router = GoRouter(
  routes: [

    GoRoute(
      path: '/',
      builder: (context, state) => HomeScreen(),
      ),
  ]
  );
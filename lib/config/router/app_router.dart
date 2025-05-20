// Update to lib/config/router/app_router.dart
import 'package:go_router/go_router.dart';
import '/presentations/screens/screen.dart';
import '/presentations/screens/eventos/my_events_screen.dart';


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
    GoRoute(
      path: '/registro',
      builder: (context, state) => const RegistroScreen(),
    ),
    GoRoute(
      path: '/eventos',
      builder: (context, state) => const EventsScreen(),
    ),
    GoRoute(
      path: '/my-events',
      builder: (context, state) => const MyEventsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/event/:id',
      builder: (context, state) {
        final eventId = state.pathParameters['id'] ?? '';
        return EventDetailScreen(eventId: eventId);
      },
    ),
  ]
);
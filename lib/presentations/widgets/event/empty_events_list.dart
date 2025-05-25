import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmptyEventsList extends StatelessWidget {
  final String message;
  final String actionText;
  final String? actionRoute;

  const EmptyEventsList({
    super.key, 
    required this.message,
    this.actionText = 'Explorar eventos',
    this.actionRoute = '/eventos',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          if (actionRoute != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(actionRoute!),
              child: Text(
                actionText,
                style: const TextStyle(
                  color: Color(0xFF0288D1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

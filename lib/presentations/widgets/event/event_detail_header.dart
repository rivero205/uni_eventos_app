import 'package:flutter/material.dart';
import '/models/event.dart';

class EventDetailHeader extends StatelessWidget {
  final Event event;

  const EventDetailHeader({
    super.key, 
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 250,
      child: Image.network(
        event.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.error_outline, size: 50),
            ),
          );
        },
      ),
    );
  }
}

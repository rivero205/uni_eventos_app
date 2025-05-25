import 'package:flutter/material.dart';
import '/models/event.dart';
import 'event_card.dart';

class EventsListWidget extends StatelessWidget {
  final List<Event> events;
  final String title;
  final double childAspectRatio;

  const EventsListWidget({
    super.key, 
    required this.events,
    this.title = 'BROWSE ALL',
    this.childAspectRatio = 0.75,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        
        // Cuadrícula de eventos
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: events.length,
          itemBuilder: (context, index) {
            return EventCard(event: events[index]);
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/models/event.dart';
import 'event_card.dart';
import 'empty_events_list.dart';

class MyEventsContent extends StatelessWidget {
  final List<Event> attendingEvents;
  
  const MyEventsContent({
    super.key,
    required this.attendingEvents,
  });

  @override
  Widget build(BuildContext context) {
    if (attendingEvents.isEmpty) {
      return EmptyEventsList(
        message: 'No estás inscrito en ningún evento',
        actionText: 'Explorar eventos',
        actionRoute: '/eventos',
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75, // Más alto que ancho
        ),
        itemCount: attendingEvents.length,
        itemBuilder: (context, index) {
          return EventCard(event: attendingEvents[index]);
        },
      ),
    );
  }
}

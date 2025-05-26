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
    
    // Separar eventos en activos y expirados
    final now = DateTime.now();
    final activeEvents = attendingEvents.where((event) => 
      now.isBefore(event.date.toDate())
    ).toList();
    
    final expiredEvents = attendingEvents.where((event) => 
      now.isAfter(event.date.toDate())
    ).toList();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de eventos activos
            if (activeEvents.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'EVENTOS PRÓXIMOS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              _buildEventsGrid(activeEvents),
              const SizedBox(height: 24),
            ],
            
            // Sección de eventos expirados
            if (expiredEvents.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'EVENTOS PASADOS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.grey,
                  ),
                ),
              ),
              _buildEventsGrid(expiredEvents),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildEventsGrid(List<Event> events) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75, // Más alto que ancho
      ),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return EventCard(event: events[index]);
      },
    );
  }
}

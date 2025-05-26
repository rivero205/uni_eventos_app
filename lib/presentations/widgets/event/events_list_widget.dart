import 'package:flutter/material.dart';
import '/models/event.dart';
import 'event_card.dart';

class EventsListWidget extends StatelessWidget {
  final List<Event> events;

  const EventsListWidget({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No hay eventos disponibles',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68, // Ajustado para hacer las tarjetas más altas
        crossAxisSpacing: 12, // Espacio horizontal entre tarjetas
        mainAxisSpacing: 8, // Reducido el espacio vertical entre tarjetas
      ),
      padding: EdgeInsets.zero, // Eliminar padding por defecto
      itemCount: events.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: EventCard(event: events[index]),
        );
      },
    );
  }
}

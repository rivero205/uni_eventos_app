import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/models/event.dart';
import 'event_info_row.dart';
import 'attend_event_button.dart';
import 'related_events_list.dart';

class EventDetailContentWidget extends StatelessWidget {
  final Event event;
  final bool isAttending;
  final bool isProcessing;
  final VoidCallback onToggleAttendance;

  const EventDetailContentWidget({
    super.key,
    required this.event,
    required this.isAttending,
    required this.isProcessing,
    required this.onToggleAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy - HH:mm').format(event.date.toDate());
    final attendeesCount = event.attendees?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Información básica del evento
          EventInfoRow(
            icon: Icons.calendar_today,
            text: 'Fecha: $formattedDate',
          ),
          const SizedBox(height: 8),
          EventInfoRow(
            icon: Icons.location_on,
            text: 'Ubicación: ${event.location}',
          ),
          
          if (event.category != null) ...[
            const SizedBox(height: 8),
            EventInfoRow(
              icon: Icons.category,
              text: 'Categoría: ${event.category}',
            ),
          ],
          
          if (event.capacity != null) ...[
            const SizedBox(height: 8),
            EventInfoRow(
              icon: Icons.people,
              text: 'Asistentes: $attendeesCount/${event.capacity}',
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Descripción
          const Text(
            'Descripción',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.description,
            style: const TextStyle(fontSize: 16),
          ),
          
          const SizedBox(height: 32),
          
          // Botón para asistir/cancelar asistencia
          AttendEventButton(
            isAttending: isAttending,
            isProcessing: isProcessing,
            onPressed: onToggleAttendance,
          ),
        ],
      ),
    );
  }
}

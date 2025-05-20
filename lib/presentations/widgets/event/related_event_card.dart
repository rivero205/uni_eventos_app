import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/models/event.dart';
import '/presentations/screens/eventos/event_detail_screen.dart';

class RelatedEventCard extends StatelessWidget {
  final Event event;

  const RelatedEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {    return InkWell(
      onTap: () {
        // Navegar al detalle del evento al hacer tap
        print('Navegando a: /event/${event.id}');
        if (event.id != null) {
          // Usar Navigator.push directamente para crear una nueva instancia
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(eventId: event.id!),
            ),
          );
        } else {
          print('Error: ID del evento es nulo');
        }
      },
      borderRadius: BorderRadius.circular(10),
      splashColor: Colors.blue.withOpacity(0.1),
      highlightColor: Colors.blue.withOpacity(0.05),
      child: Container(        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del evento
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),              child: SizedBox(
                width: 90, 
                height: 65,
                child: Image.network(
                  event.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.error_outline, size: 24),
                      ),
                    );
                  },
                ),
              ),
            ),            
            // Contenido del lado derecho (título y fecha)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Título del evento
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),                    // Fecha del evento
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(event.date.toDate()),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),                    // Sin indicador de flecha
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

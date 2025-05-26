import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/models/event.dart';

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({super.key, required this.event});
  
  @override
  Widget build(BuildContext context) {
    final bool isExpired = DateTime.now().isAfter(event.date.toDate());

    return GestureDetector(
      onTap: () {
        context.go('/event/${event.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        // Añadimos margin vertical para controlar el espacio entre tarjetas
        margin: const EdgeInsets.only(bottom: 4.0),
        child: Column(
          children: [
            // Contenedor para la imagen con altura modificada
            AspectRatio(
              aspectRatio: 4/5, // Modificamos para que sea menos alta y evitar desborde
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: Colors.grey[200],
                  child: event.imageUrl.startsWith('http') 
                    ? Image.network(
                        event.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.error_outline, size: 30),
                          );
                        },
                      )
                    : Image.asset(
                        event.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.error_outline, size: 30),
                          );
                        },
                      ),
                ),
              ),
            ),
            
            // Título del evento (centrado) con padding ajustado
            Padding(
              padding: const EdgeInsets.only(top: 6.0, left: 4.0, right: 4.0, bottom: 2.0),
              child: Text(
                event.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isExpired ? Colors.grey : Colors.black,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

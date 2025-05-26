import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/models/event.dart';

class FeaturedEventCard extends StatelessWidget {
  final Event event;

  const FeaturedEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final bool isExpired = DateTime.now().isAfter(event.date.toDate());
    
    return GestureDetector(
      onTap: () {
        // Navegar al detalle del evento
        context.go('/event/${event.id}');
      },
      child: Column(
        children: [
          // Imagen del evento destacado con indicador de expiración
          Stack(
            children: [              // Imagen del evento
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1.0, // Relación cuadrada para la imagen destacada
                  child: event.imageUrl.startsWith('http')
                    ? Image.network(
                        event.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.error_outline, size: 30),
                            ),
                          );
                        },
                      )
                    : Image.asset(
                        event.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.error_outline, size: 30),
                            ),
                          );
                        },
                      ),
                ),
              ),
            ],
          ),
          
          // Título del evento destacado (centrado)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: Text(
                event.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isExpired ? Colors.grey : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

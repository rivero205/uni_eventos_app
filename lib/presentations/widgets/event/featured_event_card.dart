import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/models/event.dart';

class FeaturedEventCard extends StatelessWidget {
  final Event event;

  const FeaturedEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navegar al detalle del evento
        context.go('/event/${event.id}');
      },
      child: Column(
        children: [
          // Imagen del evento destacado
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1.0, // Relación cuadrada para la imagen destacada
              child: Image.network(
                event.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          
          // Título del evento destacado (centrado)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: Text(
                event.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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

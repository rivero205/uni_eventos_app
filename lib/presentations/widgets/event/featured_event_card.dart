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
        context.go('/event/${event.id}');
      },
      child: Container(
        width: double.infinity,
        // Removemos las constraints rígidas para dar más flexibilidad
        margin: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagen del evento con altura fija más grande
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: double.infinity,
                height: 350, // Altura más alta para una mejor presencia visual
                child: event.imageUrl.startsWith('http')
                  ? Image.network(
                      event.imageUrl,
                      fit: BoxFit.cover, // Mantiene las proporciones naturales
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
            
            // Título del evento destacado
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
              child: Center(
                child: Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 17, // Aumentamos un poco el tamaño
                    fontWeight: FontWeight.bold,
                    color: isExpired ? Colors.grey : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
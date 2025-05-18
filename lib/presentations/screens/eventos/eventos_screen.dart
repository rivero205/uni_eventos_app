import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/models/event.dart';
import '../widgets/bottom_nav_bar.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener lista de eventos de ejemplo
    final events = Event.getSampleEvents();
    
    // El primer evento será el destacado
    final featuredEvent = events.first;
    
    // El resto de eventos para la cuadrícula
    final gridEvents = events.sublist(1);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Eventos',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          // Botón para cerrar sesión
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'logout') {
                // Navegar a la pantalla de inicio
                context.go('/');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Cerrar sesión'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtítulo "NOVEDADES DE HOY"
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'NOVEDADES DE HOY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              
              // Evento destacado
              GestureDetector(
                onTap: () {
                  // Navegar al detalle del evento destacado
                  context.go('/event/${featuredEvent.id}');
                },
                child: FeaturedEventCard(event: featuredEvent),
              ),
              
              // Título "BROWSE ALL"
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 16, 0, 12),
                child: Text(
                  'BROWSE ALL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              
              // Cuadrícula de eventos con tamaño más grande
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  // Usar un aspect ratio que haga las tarjetas más altas
                  childAspectRatio: 0.75, // Más alto que ancho
                ),
                itemCount: gridEvents.length,
                itemBuilder: (context, index) {
                  return EventCard(event: gridEvents[index]);
                },
              ),
              
              // Espacio adicional al final para que no se oculte contenido detrás de la barra de navegación
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}

// Widget para el evento destacado
class FeaturedEventCard extends StatelessWidget {
  final Event event;

  const FeaturedEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

// Widget para cada tarjeta de evento en la cuadrícula
class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navegar al detalle del evento
        context.go('/event/${event.id}');
      },
      child: Column(
        children: [
          // Contenedor para la imagen
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                color: Colors.grey[200], // Color de fondo por si la imagen no carga
                child: Image.network(
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
                ),
              ),
            ),
          ),
          
          // Título del evento (centrado)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: Text(
                event.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
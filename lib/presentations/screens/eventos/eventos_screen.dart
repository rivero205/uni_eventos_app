import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EventosScreen extends StatelessWidget {
  const EventosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        // Reemplazamos el IconButton con nuestro menú dinámico
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      // Agregamos el Drawer (menú lateral)
      drawer: const AppDrawer(),
      body: const EventosLayout(),
    );
  }
}

// Widget para el menú lateral (Drawer)
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Cabecera del drawer con información del usuario
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF0288D1),
            ),
            accountName: const Text(
              'Usuario UniEventos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            accountEmail: const Text('usuario@ejemplo.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                'U',
                style: TextStyle(
                  fontSize: 24.0,
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Opción de Perfil
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi Perfil'),
            onTap: () {
              // Cerrar el drawer
              Navigator.pop(context);
              // Aquí iría la navegación al perfil (sin implementar)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidad de Perfil no implementada'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          
          const Divider(),
          
          // Opción de Cerrar Sesión
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              // Cerrar el drawer
              Navigator.pop(context);
              // Navegar a la pantalla Home
              context.go('/');
            },
          ),
        ],
      ),
    );
  }
}

class EventosLayout extends StatelessWidget {
  const EventosLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: News of today
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              'NOVEDADES DE HOY',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          
          // Feature Event Card
          GestureDetector(
            onTap: () {
              // Navigate to event details
            },
            child: const FeaturedEventCard(
              imageUrl: 'assets/arquitectura_moderna.jpg',
              title: 'Arquitectura Moderna',
            ),
          ),
          
          // Browse All Section Title
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 20, bottom: 8),
            child: Text(
              'BROWSE ALL',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          
          // Grid of Events
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: EventsGrid(events: sampleEvents),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class FeaturedEventCard extends StatelessWidget {
  final String imageUrl;
  final String title;

  const FeaturedEventCard({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: double.infinity,
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image (using placeholder color until image is loaded)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: Center(
                    child: Icon(Icons.image, size: 50, color: Colors.grey.shade600),
                  ),
                );
              },
            ),
          ),
          
          // Title overlay at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventsGrid extends StatelessWidget {
  final List<Event> events;

  const EventsGrid({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return EventCard(event: events[index]);
      },
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to event details
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster/Image
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                event.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Icon(Icons.image, size: 40, color: Colors.grey.shade400),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              event.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Model class for events
class Event {
  final String title;
  final String imageUrl;
  final String? description;
  final DateTime? date;

  const Event({
    required this.title,
    required this.imageUrl,
    this.description,
    this.date,
  });
}

// Sample data for events
final List<Event> sampleEvents = [
  const Event(
    title: 'V Congreso',
    imageUrl: 'assets/v_congreso.jpg',
    description: 'Congreso de Ingeniería de Sistemas e Informática',
  ),
  const Event(
    title: 'Ingeniería HOY',
    imageUrl: 'assets/ingenieria_hoy.jpg',
    description: 'Centro Interactivo de Ingeniería de Sistemas e Informática',
  ),
  const Event(
    title: 'Sistemas Fotovoltaicos',
    imageUrl: 'assets/sistemas_fotovoltaicos.jpg',
    description: 'Sistemas Fotovoltaicos Aislados de la Red',
  ),
  const Event(
    title: 'Sistemas de I',
    imageUrl: 'assets/sistemas_i.jpg',
    description: 'Conferencia sobre Sistemas de Información',
  ),
  const Event(
    title: 'V Congreso',
    imageUrl: 'assets/v_congreso.jpg',
    description: 'Congreso de Ingeniería de Sistemas e Informática',
  ),
  const Event(
    title: 'Ingeniería HOY',
    imageUrl: 'assets/ingenieria_hoy.jpg',
    description: 'Centro Interactivo de Ingeniería de Sistemas e Informática',
  ),
];
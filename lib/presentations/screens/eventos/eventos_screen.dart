import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/models/event.dart';
import '/services/event_service.dart';
import '/presentations/widgets/bottom_nav_bar.dart';
import '/presentations/widgets/event/featured_event_card.dart';
import '/presentations/widgets/event/events_list_widget.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventService _eventService = EventService();
  bool _isLoading = true;
  String? _errorMessage;
  Stream<List<Event>>? _eventsStream;

  @override
  void initState() {
    super.initState();
    // Inicializamos el stream para escuchar cambios en tiempo real
    _eventsStream = _eventService.getEventsStream();
    _checkConnectivity();
  }
  
  // Método para verificar la conectividad
  Future<void> _checkConnectivity() async {
    try {
      final isOffline = await _eventService.isOfflineMode();
      if (isOffline) {
        setState(() {
          _errorMessage = "Modo offline - Mostrando datos guardados";
        });
      }
    } catch (e) {
      print('Error al verificar conectividad: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshEvents() async {
    // Este método ahora solo es para mostrar el indicador de refresh
    // pero el StreamBuilder actualizará automáticamente la UI
    try {
      await _eventService.refreshEvents();
      setState(() {
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error al actualizar eventos: $e";
      });
    }
    return Future.delayed(Duration.zero); // Para cerrar el indicador de refresh
  }
  Widget _buildErrorMessage() {
    // Determinar si es un mensaje de modo offline o un error real
    final bool isOfflineMode = _errorMessage != null && _errorMessage!.contains("offline");
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      decoration: BoxDecoration(
        color: isOfflineMode
          ? Colors.orange.shade100  // Warning para offline mode
          : Colors.red.shade100,    // Error para sin eventos
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOfflineMode
            ? Colors.orange.shade300 
            : Colors.red.shade300
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOfflineMode
              ? Icons.info 
              : Icons.error_outline,
            color: isOfflineMode
              ? Colors.orange.shade700 
              : Colors.red.shade700
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: isOfflineMode
                  ? Colors.orange.shade700 
                  : Colors.red.shade700
              ),
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
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
          // Icono de búsqueda
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                context.go('/search');
              },
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF0288D1),
                child: Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          // Icono de perfil
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                context.go('/profile');
              },
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF0288D1),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEvents,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Event>>(
              stream: _eventsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error al cargar eventos: ${snapshot.error}'),
                  );
                }
                
                // Obtener y procesar los eventos del stream
                List<Event> events = snapshot.data ?? [];
                
                // Si no hay eventos, mostrar mensaje vacío
                if (events.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height / 4),
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay eventos disponibles',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // Seleccionar el evento destacado (el más reciente)
                Event featuredEvent = events.first;
                
                // Eventos para la cuadrícula (todos excepto el destacado)
                List<Event> gridEvents = events.where((e) => e.id != featuredEvent.id).toList();
                
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null)
                        _buildErrorMessage(),
                      
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12, top: 16),
                        child: Text(
                          'NOVEDADES DE HOY',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      FeaturedEventCard(event: featuredEvent),
                      
                      if (gridEvents.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'TODOS LOS EVENTOS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        EventsListWidget(events: gridEvents),
                      ],
                      
                      const SizedBox(height: 60), // Espacio para el bottom nav bar
                    ],
                  ),
                );
              },
            ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}

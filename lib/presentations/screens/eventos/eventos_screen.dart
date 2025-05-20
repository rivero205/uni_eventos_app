import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/models/event.dart';
import '/services/event_service.dart';
import '/presentations/widgets/bottom_nav_bar.dart';
import '/presentations/widgets/event/event_card.dart';
import '/presentations/widgets/event/featured_event_card.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventService _eventService = EventService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Event>? _events;
  Event? _featuredEvent;
  List<Event>? _gridEvents;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Obtener lista de eventos de Firestore
      final events = await _eventService.getEvents();
      
      if (events.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = "No hay eventos disponibles";
          _events = [];
        });
        return;
      }
      
      setState(() {
        _events = events;
        // El primer evento será el destacado
        _featuredEvent = events.first;
        // El resto de eventos para la cuadrícula
        _gridEvents = events.length > 1 ? events.sublist(1) : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error al cargar los eventos: $e";
        // Intentar usar los eventos de muestra como fallback
        try {
          _events = _eventService.getSampleEvents();
          if (_events!.isNotEmpty) {
            _featuredEvent = _events!.first;
            _gridEvents = _events!.length > 1 ? _events!.sublist(1) : [];
            _errorMessage = "Usando datos locales. Error de conexión: $e";
          }
        } catch (_) {
          _events = [];
          _errorMessage = "No se pudieron cargar los eventos.";
        }
      });
    }
  }
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              const Icon(Icons.logout, color: Color(0xFF0288D1)),
              const SizedBox(width: 10),
              const Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            '¿Estás seguro que deseas cerrar sesión?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Sí, cerrar sesión'),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,      
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Eventos',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          // Botón para ir al perfil
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
        ],      ),
      body: _errorMessage != null && (_events == null || _events!.isEmpty)
          ? _buildErrorView()
          : RefreshIndicator(
              onRefresh: _loadEvents,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtítulo "NOVEDADES DE HOY"
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12, top: 16),
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
                      if (_featuredEvent != null)
                        FeaturedEventCard(event: _featuredEvent!),
                      
                      // Título "BROWSE ALL"
                      if (_gridEvents != null && _gridEvents!.isNotEmpty) ...[
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
                        
                        // Cuadrícula de eventos
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75, // Más alto que ancho
                          ),
                          itemCount: _gridEvents!.length,
                          itemBuilder: (context, index) {
                            return EventCard(event: _gridEvents![index]);
                          },
                        ),
                      ],
                      
                      // Espacio adicional al final
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? "Error desconocido",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadEvents,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text("Reintentar"),
            ),
          ],
        ),
      ),
    );
  }
}
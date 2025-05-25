import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/models/event.dart';
import '/services/event_service.dart';
import '/presentations/widgets/bottom_nav_bar.dart';
import '/presentations/widgets/event/featured_event_card.dart';
import '/presentations/widgets/event/events_list_widget.dart';
import '/presentations/widgets/event/events_error_widget.dart';
import '/presentations/widgets/event/events_loading_widget.dart';

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
  }  // El diálogo de cierre de sesión se manejará en otro componente si es necesario@override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: EventsLoadingWidget(),
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
        ],
      ),
      body: _errorMessage != null && (_events == null || _events!.isEmpty)
          ? EventsErrorWidget(
              errorMessage: _errorMessage ?? "Error desconocido",
              onRetry: _loadEvents,
            )
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
                      
                      // Lista de eventos en grid
                      if (_gridEvents != null && _gridEvents!.isNotEmpty)
                        EventsListWidget(events: _gridEvents!),
                      
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
  // Las funcionalidades de error ahora se manejan con EventsErrorWidget
}
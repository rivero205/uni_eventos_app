import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/event.dart';
import '/services/event_service.dart';
import '/services/notification_service.dart';
import '/presentations/widgets/bottom_nav_bar.dart';
import '/presentations/widgets/event/event_card.dart';
import '/presentations/widgets/event/featured_event_card.dart';
// import 'package:myapp/presentations/screens/eventos/search_event_screen.dart'; // Will be removed
import 'package:myapp/presentations/screens/widgets/general_search_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Event query
import 'package:myapp/presentations/screens/eventos/event_detail_screen.dart'; // For navigation from search results


class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventService _eventService = EventService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  String? _errorMessage;
  List<Event>? _events; // All events for normal view
  Event? _featuredEvent;
  List<Event>? _gridEvents;

  // Search related state variables
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  Stream<List<Event>>? _searchedEventsStream;
  List<String> _searchHistory = [];
  static const String _searchHistoryKey = 'search_history_events_screen'; // Make key unique if SearchEventScreen is kept elsewhere
  static const String _hasSearchedKey = 'has_searched_before_events_screen';
  final int _maxHistoryItems = 10;
  bool _hasSearchedBefore = false;
  bool _isLoadingHistory = true;
  final FocusNode _searchFocusNode = FocusNode();


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
      // Verificar si estamos en modo offline
      final isOffline = await _eventService.isOfflineMode();
      
      // Obtener lista de eventos (desde Firestore o cache local)
      final events = await _eventService.getEvents();
      
      if (events.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = isOffline 
            ? "Sin conexión y sin datos guardados" 
            : "No hay eventos disponibles";
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
        
        // Mostrar indicador de modo offline si es necesario
        if (isOffline && events.isNotEmpty) {
          _errorMessage = "Modo offline - Mostrando datos guardados";
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error al cargar los eventos: $e";
        _events = [];
      });
    }
  }  
  // Método para forzar actualización (pull to refresh)
  Future<void> _refreshEvents() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final events = await _eventService.refreshEvents();
      
      setState(() {
        _events = events;
        _featuredEvent = events.isNotEmpty ? events.first : null;
        _gridEvents = events.length > 1 ? events.sublist(1) : [];
        _isLoading = false;
      });
    }
  }  // El diálogo de cierre de sesión se manejará en otro componente si es necesario@override
  Widget build(BuildContext context) {
    if (_isLoading && !_isSearching) { // Only show main loading if not searching
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
        leading: _isSearching ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = ""; // Clear search query when exiting search mode
              _searchController.clear();
              _searchedEventsStream = Stream.value([]); // Clear results
            });
            FocusScope.of(context).unfocus();
          },
        ) : null, // No leading icon when not searching (or keep default if any)
        title: _isSearching 
            ? GeneralSearchWidget(
                controller: _searchController,
                currentQuery: _searchQuery,
                focusNode: _searchFocusNode,
                onClear: () {
                  _searchController.clear();
                  _onSearchQueryChanged("");
                },
                onSubmitted: _onSearchSubmitted,
                onChanged: _onSearchQueryChanged,
                labelText: 'Buscar eventos',
                hintText: 'Nombre, descripción o ubicación...',
              )
            : const Text(
                'Eventos',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
        actions: _isSearching 
            ? [
                // Optionally add a clear all text button if needed, or keep it minimal
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                    // Request focus after a short delay to ensure widget is built
                    Future.delayed(const Duration(milliseconds: 100), () {
                        FocusScope.of(context).requestFocus(_searchFocusNode);
                    });
                  },
                  tooltip: 'Buscar eventos',
                ),
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

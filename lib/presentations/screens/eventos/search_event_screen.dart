import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/models/event.dart';
import '/services/event_service.dart';
import '/presentations/widgets/event/event_card.dart';

class SearchEventScreen extends StatefulWidget {
  const SearchEventScreen({super.key});

  @override
  State<SearchEventScreen> createState() => _SearchEventScreenState();
}

class _SearchEventScreenState extends State<SearchEventScreen> {
  final EventService _eventService = EventService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  List<Event> _searchResults = [];
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Cargamos la lista de eventos al inicio para tener resultados en caché
    _preloadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  
  // Precarga de eventos para mejorar la experiencia de búsqueda
  Future<void> _preloadEvents() async {
    try {
      await _eventService.getEvents();
    } catch (e) {
      print('Error al precargar eventos: $e');
    }
  }

  Future<void> _searchEvents(String query) async {
    // Cancelar el timer anterior si existe
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    
    // Asignar la consulta actual inmediatamente
    setState(() {
      _searchQuery = query;
    });
    
    // Si está vacía, limpiar resultados inmediatamente
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    
    // Iniciar un nuevo timer para retrasar la búsqueda
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Obtenemos todos los eventos y luego filtramos por la consulta
        final events = await _eventService.getEvents();
        
        // Filtrar eventos basados en título, descripción, ubicación o categoría
        final filteredEvents = events.where((event) {
          final title = event.title.toLowerCase();
          final description = event.description.toLowerCase();
          final location = event.location.toLowerCase();
          final category = event.category?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          
          return title.contains(searchLower) || 
                description.contains(searchLower) || 
                location.contains(searchLower) || 
                category.contains(searchLower);
        }).toList();
        
        setState(() {
          _searchResults = filteredEvents;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = "Error al buscar eventos: $e";
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar eventos'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/eventos');
          },
        ),
      ),
      // Usamos resizeToAvoidBottomInset: false para evitar que el scaffold se redimensione con el teclado
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar eventos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchEvents('');
                        },
                      ) 
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onSubmitted: _searchEvents,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                _searchEvents(value);
              },
            ),
          ),
          
          // Contenido principal - Usamos un Expanded para que ocupe el espacio restante
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null 
                  ? Center(child: Text(_errorMessage!))
                  : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      // Posicionamos el icono y el texto en una posición fija usando Stack y Positioned
      return Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2, // Posición fija desde arriba
            left: 0,
            right: 0,
            child: Column(
              children: [
                Icon(
                  Icons.search,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    'Busca eventos por título, descripción, ubicación o categoría',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    if (_searchResults.isEmpty) {
      // Similar para el mensaje de no resultados
      return Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Icon(
                  Icons.event_busy,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    'No se encontraron eventos para "$_searchQuery"',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.67,
        ),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          return EventCard(event: _searchResults[index]);
        },
      ),
    );
  }
}

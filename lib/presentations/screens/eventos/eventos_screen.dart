import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/models/event.dart';
import '/services/event_service.dart';
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
    _loadEvents(); // Load all events for normal display
    _initializeSearchState(); // Load search history etc.
    // Listener for search query changes is handled by GeneralSearchWidget's onChanged
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // --- Search Functionality Methods (to be ported from SearchEventScreen) ---

  Future<void> _initializeSearchState() async {
    await Future.wait([
      _loadSearchHistory(),
      _loadSearchStatePrefs(), // Renamed to avoid conflict if original _loadSearchState exists
    ]);
    if (mounted) {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _searchHistory = prefs.getStringList(_searchHistoryKey) ?? [];
        });
      }
    } catch (e) {
      debugPrint('EventsScreen: Error loading search history: $e');
      if (mounted) {
        setState(() {
          _searchHistory = [];
        });
      }
    }
  }

  Future<void> _loadSearchStatePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _hasSearchedBefore = prefs.getBool(_hasSearchedKey) ?? false;
        });
      }
    } catch (e) {
      debugPrint('EventsScreen: Error loading search state: $e');
    }
  }

  Future<void> _saveSearchTerm(String term) async {
    if (term.trim().isEmpty) return;
    final cleanTerm = term.trim().toLowerCase();
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> updatedHistory = List.from(_searchHistory);
      updatedHistory.removeWhere((item) => item.toLowerCase() == cleanTerm);
      updatedHistory.insert(0, term.trim());
      if (updatedHistory.length > _maxHistoryItems) {
        updatedHistory = updatedHistory.sublist(0, _maxHistoryItems);
      }
      await Future.wait([
        prefs.setStringList(_searchHistoryKey, updatedHistory),
        prefs.setBool(_hasSearchedKey, true),
      ]);
      if (mounted) {
        setState(() {
          _searchHistory = updatedHistory;
          _hasSearchedBefore = true;
        });
      }
    } catch (e) {
      debugPrint('EventsScreen: Error saving search term: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar la búsqueda')),
        );
      }
    }
  }

  void _onSearchQueryChanged(String query) {
    if (_searchQuery != query) {
      setState(() {
        _searchQuery = query;
      });
      _updateSearchedEventsStream();
    }
  }

  void _updateSearchedEventsStream() {
    if (_searchQuery.trim().isEmpty) {
      setState(() {
        _searchedEventsStream = Stream.value([]);
      });
      return;
    }
    setState(() {
      _searchedEventsStream = FirebaseFirestore.instance
          .collection('events')
          .snapshots()
          .map((snapshot) {
        final queryLower = _searchQuery.trim().toLowerCase();
        return snapshot.docs
            .map((doc) => Event.fromFirestore(doc))
            .where((event) {
              return event.title.toLowerCase().contains(queryLower) ||
                     event.description.toLowerCase().contains(queryLower) ||
                     event.location.toLowerCase().contains(queryLower);
            })
            .toList()
            ..sort((a, b) {
              final aStartsWith = a.title.toLowerCase().startsWith(queryLower);
              final bStartsWith = b.title.toLowerCase().startsWith(queryLower);
              if (aStartsWith && !bStartsWith) return -1;
              if (!aStartsWith && bStartsWith) return 1;
              return a.title.compareTo(b.title);
            });
      });
    });
  }

  void _onSearchSubmitted(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isNotEmpty) {
      _saveSearchTerm(trimmedQuery);
      // FocusScope.of(context).unfocus(); // GeneralSearchWidget might handle this or not needed if search bar persists
    }
    // Keep search active, results will update
  }

  void _onRecentSearchTapped(String term) {
    _searchController.text = term;
    _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: term.length));
    _onSearchQueryChanged(term); // This will trigger stream update
    // No need to manually request focus if search bar is already visible
  }

  Future<void> _deleteSearchTerm(String term) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedHistory = _searchHistory.where((item) => item != term).toList();
      await prefs.setStringList(_searchHistoryKey, updatedHistory);
      if (mounted) {
        setState(() {
          _searchHistory = updatedHistory;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Búsqueda "$term" eliminada'),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () => _undoDeleteSearchTerm(term),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('EventsScreen: Error deleting search term: $e');
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar la búsqueda')),
        );
      }
    }
  }

  Future<void> _undoDeleteSearchTerm(String term) async {
    await _saveSearchTerm(term); // This will re-add and move to top
  }

  Future<void> _confirmClearSearchHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) { // Use different context name
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Limpiar historial'),
          ]),
          content: const Text('¿Estás seguro de que quieres borrar todo el historial de búsqueda? Esta acción no se puede deshacer.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Limpiar todo'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      await _clearSearchHistory();
    }
  }

  Future<void> _clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
      if (mounted) {
        setState(() {
          _searchHistory.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Historial de búsqueda limpiado')),
        );
      }
    } catch (e) {
      debugPrint('EventsScreen: Error clearing search history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al limpiar el historial')),
        );
      }
    }
  }
  // --- End of Search Functionality Methods ---

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
  // --- UI Building methods for Search ---
  Widget _buildSearchHistoryWidget() {
    if (_searchQuery.isNotEmpty || (!_hasSearchedBefore && _searchHistory.isEmpty) || _isLoadingHistory) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.history, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Text('Búsquedas recientes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              ]),
              if (_searchHistory.isNotEmpty)
                TextButton(
                  onPressed: _confirmClearSearchHistory,
                  child: const Text('Limpiar todo', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w500)),
                ),
            ],
          ),
        ),
        if (_searchHistory.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('No hay búsquedas recientes', style: TextStyle(color: Colors.grey, fontSize: 16)),
                Text('Tus búsquedas aparecerán aquí', style: TextStyle(color: Colors.grey, fontSize: 14)),
              ]),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _searchHistory.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 56),
            itemBuilder: (context, index) {
              final term = _searchHistory[index];
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey, size: 20),
                title: Text(term, style: const TextStyle(fontSize: 16)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  onPressed: () => _deleteSearchTerm(term),
                  tooltip: 'Eliminar búsqueda',
                ),
                onTap: () => _onRecentSearchTapped(term),
              );
            },
          ),
        const SizedBox(height: 8),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildSearchResultsWidget() {
    return StreamBuilder<List<Event>>(
      stream: _searchedEventsStream,
      builder: (context, snapshot) {
        if (_searchQuery.isEmpty && !_isSearching) { // Should not be visible if not searching and query is empty
          return const SizedBox.shrink();
        }
        if (snapshot.connectionState == ConnectionState.waiting && _searchQuery.isNotEmpty) {
          return const Expanded(child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Expanded(child: Center(child: Text('Error: ${snapshot.error}')));
        }
        final events = snapshot.data ?? [];
        if (_searchQuery.isNotEmpty && events.isEmpty) {
          return const Expanded(
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No se encontraron eventos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Intenta con otros términos de búsqueda', style: TextStyle(color: Colors.grey)),
              ]),
            ),
          );
        }

        // Only build if there are events to show or if it's the initial state of active search
        if (events.isEmpty && _searchQuery.isEmpty) { // Handles case where stream is empty but search just started
            return const SizedBox.shrink(); 
        }


        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_searchQuery.isNotEmpty) // Show count only when there's an active search query
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    '${events.length} resultado${events.length != 1 ? 's' : ''} encontrado${events.length != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const SizedBox(height: 4),
                          Text(event.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Expanded(child: Text(event.location, style: TextStyle(color: Colors.grey[500], fontSize: 12))),
                          ]),
                          const SizedBox(height: 2),
                          Row(children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text('${event.date.toDate().day}/${event.date.toDate().month}/${event.date.toDate().year}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          ]),
                        ]),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: event.imageUrl.isNotEmpty
                              ? Image.network(event.imageUrl, width: 60, height: 60, fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.event, size: 30, color: Colors.grey)))
                              : Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.event, size: 30, color: Colors.grey)),
                        ),
                        onTap: () {
                          if (event.id != null) {
                            FocusScope.of(context).unfocus(); // Unfocus before navigating
                            context.push('/event/${event.id}').then((_) { // Use GoRouter's push
                              // This block executes when EventDetailScreen is popped
                              if (mounted && _isSearching) {
                                setState(() {
                                  _isSearching = false;
                                  _searchQuery = "";
                                  _searchController.clear();
                                  _searchedEventsStream = Stream.value([]);
                                  // Focus is already handled before push, no need to unfocus again here
                                });
                              }
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  // --- End of UI Building methods for Search ---


  @override
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
      body: _isSearching
          ? Column( // Search UI
              children: [
                // Search history or results
                if (_searchQuery.isEmpty)
                  _buildSearchHistoryWidget()
                else
                  _buildSearchResultsWidget(),
              ],
            )
          : (_errorMessage != null && (_events == null || _events!.isEmpty)) // Normal view (or error)
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

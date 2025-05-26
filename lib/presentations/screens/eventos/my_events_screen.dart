import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/event.dart';
import '/models/user_model.dart';
import '/services/notification_service.dart';
import '/presentations/widgets/bottom_nav_bar.dart';
import '/presentations/widgets/event/event_card.dart';
import 'package:go_router/go_router.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  
  bool _isLoading = true;
  List<Event> _attendingEvents = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserEvents();
  }

  Future<void> _loadUserEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'No hay usuario autenticado';
          _isLoading = false;
        });
        return;
      }

      // Obtener datos del usuario desde Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        setState(() {
          _error = 'No se encontraron datos del usuario';
          _isLoading = false;
        });
        return;
      }
      
      // Obtener información del usuario
      UserModel userModel = UserModel.fromFirestore(userDoc);
      
      // Obtener eventos a los que asiste
      _attendingEvents = await _fetchAttendingEvents(userModel);
      
      // Verificar si hay eventos expirados y mostrar notificación
      _checkAndNotifyExpiredEvents(currentUser.uid);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }
  
  // Método para verificar y notificar eventos expirados
  Future<void> _checkAndNotifyExpiredEvents(String userId) async {
    final expiredEvents = await _notificationService.checkExpiredEventsForUser(userId, context);
    if (expiredEvents.isNotEmpty) {
      _notificationService.showEventExpirationNotification(context, expiredEvents);
    }
  }
  
  Future<List<Event>> _fetchAttendingEvents(UserModel userModel) async {
    if (userModel.eventsAttending == null || userModel.eventsAttending!.isEmpty) {
      return [];
    }
    
    try {
      final List<Event> events = [];
      
      // Primero intentamos obtener eventos de Firestore
      for (String eventId in userModel.eventsAttending!) {
        try {
          DocumentSnapshot eventDoc = await _firestore
              .collection('events')
              .doc(eventId)
              .get();
              
          if (eventDoc.exists) {
            events.add(Event.fromFirestore(eventDoc));
          }
        } catch (e) {
          print('Error fetching event $eventId: $e');
        }
      }
        // Si no encontramos eventos en Firestore, buscar en cache local
      if (events.isEmpty) {
        // Como alternativa, podríamos intentar buscar en cache local
        // pero por ahora simplemente devolvemos una lista vacía
        print('No se encontraron eventos para los IDs del usuario');
      }
      
      return events;
    } catch (e) {
      print('Error fetching attending events: $e');
      return [];
    }
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
    
    return Scaffold(      appBar: AppBar(
        title: const Text(
          'Mis Eventos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Colors.black,
          ),
        ),
        
      ),
      body: _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : _buildEventsList(),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
  
  Widget _buildEventsList() {
    if (_attendingEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No estás inscrito en ningún evento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            //
            const SizedBox(height: 8),
            TextButton(
                onPressed: () => context.go('/eventos'),
              child: const Text(
                'Explorar eventos',
                style: TextStyle(
                  color: Color(0xFF0288D1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75, // Más alto que ancho
        ),
        itemCount: _attendingEvents.length,
        itemBuilder: (context, index) {
          return EventCard(event: _attendingEvents[index]);
        },
      ),
    );
  }
}

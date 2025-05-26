// filepath: lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/models/event.dart';

class NotificationService {
  final FirebaseFirestore _firestore;
  
  NotificationService({
    FirebaseFirestore? firestore
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Método para verificar si hay eventos expirados para un usuario y mostrar notificación
  Future<List<Event>> checkExpiredEventsForUser(String userId, BuildContext context) async {
    if (userId.isEmpty) return [];
    
    try {
      // Obtener los eventos a los que asiste el usuario
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
          
      if (!userDoc.exists) return [];
      
      final userData = userDoc.data();
      final List<String> userEventsAttending = userData?['eventsAttending'] != null 
          ? List<String>.from(userData?['eventsAttending']) 
          : [];
      
      if (userEventsAttending.isEmpty) return [];
      
      // Obtener los detalles de los eventos
      List<Event> expiredEvents = [];
      final now = DateTime.now();
      
      for (String eventId in userEventsAttending) {
        final eventDoc = await _firestore
            .collection('events')
            .doc(eventId)
            .get();
            
        if (eventDoc.exists) {
          final event = Event.fromFirestore(eventDoc);
          final eventDate = event.date.toDate();
          
          // Verificar si el evento ha expirado
          if (now.isAfter(eventDate)) {
            expiredEvents.add(event);
          }
        }
      }
      
      return expiredEvents;
    } catch (e) {
      print('Error al verificar eventos expirados: $e');
      return [];
    }
  }
  
  // Método para mostrar notificación en la UI
  void showEventExpirationNotification(
    BuildContext context, 
    List<Event> expiredEvents
  ) {
    if (expiredEvents.isEmpty) return;
    
    final count = expiredEvents.length;
    
    // Mostrar SnackBar con la notificación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.amber.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              const Icon(Icons.event_busy, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  count == 1 
                    ? 'Un evento al que te inscribiste ha finalizado.'
                    : '$count eventos a los que te inscribiste han finalizado.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Ver',
            textColor: Colors.white,
            onPressed: () {
              // Navegar a la pantalla de mis eventos
              Navigator.of(context).pushNamed('/my-events');
            },
          ),
        ),
      );
    });
  }
}

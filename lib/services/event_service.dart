import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/event.dart';

class EventService {
  final FirebaseFirestore _firestore;
  
  EventService({
    FirebaseFirestore? firestore
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Obtener lista de eventos desde Firestore
  Future<List<Event>> getEvents() async {
    return await Event.getEventsFromFirestore();
  }
  
  // Obtener lista de eventos de ejemplo (mantiene compatibilidad)
  List<Event> getSampleEvents() {
    return Event.getSampleEvents();
  }
  
  // Obtener un evento por ID
  Future<Event?> getEventById(String eventId) async {
    try {
      // Intentar cargar el evento desde Firestore
      final eventDoc = await _firestore
          .collection('events')
          .doc(eventId)
          .get();
          
      if (eventDoc.exists) {
        return Event.fromFirestore(eventDoc);
      }
      
      // Si no existe en Firestore, usar eventos de ejemplo como respaldo
      final events = getSampleEvents();
      return events.firstWhere(
        (e) => e.id == eventId,
        orElse: () => throw Exception('Evento no encontrado'),
      );
    } catch (e) {
      print('Error al obtener evento por ID: $e');
      rethrow;
    }
  }
  // Obtener eventos relacionados (excluyendo un evento específico)
  Future<List<Event>> getRelatedEvents(String currentEventId) async {
    try {
      // Obtener todos los eventos desde Firestore
      final List<Event> allEvents = await getEvents();
      
      // Filtrar para eliminar el evento actual
      return allEvents
          .where((e) => e.id != currentEventId)
          .toList();
    } catch (e) {
      print('Error al obtener eventos relacionados: $e');
      // Usar datos de ejemplo como fallback
      final allEvents = getSampleEvents();
      return allEvents
          .where((e) => e.id != currentEventId)
          .toList();
    }
  }

  // Verificar si un usuario está asistiendo a un evento
  Future<bool> isUserAttendingEvent(String userId, String eventId) async {
    if (userId.isEmpty) return false;
    
    try {
      // Verificar en el documento del evento
      final eventDoc = await _firestore
          .collection('events')
          .doc(eventId)
          .get();
          
      if (eventDoc.exists) {
        final event = Event.fromFirestore(eventDoc);
        return event.attendees?.contains(userId) ?? false;
      }
      
      // Si no existe el evento en Firestore, verificar en el documento del usuario
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
          
      if (userDoc.exists) {
        final userData = userDoc.data();
        final List<String> userEventsAttending = userData?['eventsAttending'] != null 
            ? List<String>.from(userData?['eventsAttending']) 
            : [];
            
        return userEventsAttending.contains(eventId);
      }
      
      return false;
    } catch (e) {
      print('Error al verificar asistencia: $e');
      return false;
    }
  }

  // Actualizar asistencia de un usuario a un evento
  Future<void> toggleEventAttendance(
    String userId,
    String eventId,
    Event event,
    bool currentAttendingState,
  ) async {
    if (userId.isEmpty) {
      throw Exception('Usuario no autenticado');
    }

    try {
      // Usar una transacción para actualizar tanto el documento del evento como el del usuario
      await _firestore.runTransaction((transaction) async {
        // Referencias a los documentos del evento y del usuario
        final eventRef = _firestore.collection('events').doc(eventId);
        final userRef = _firestore.collection('users').doc(userId);
        
        // Obtener los documentos actuales
        final eventDoc = await transaction.get(eventRef);
        final userDoc = await transaction.get(userRef);
        
        // Verificar si los eventos están en la base de datos real o son ejemplos
        if (!eventDoc.exists && event.id != null) {
          // En caso de que estemos usando eventos de ejemplo, crearlos en Firestore
          final eventData = event.toJson();
          eventData['id'] = event.id; // Añadir el ID explícitamente
          transaction.set(eventRef, eventData);
        }
        
        // Preparar las actualizaciones
        final bool willAttend = !currentAttendingState;
        
        // Actualizar la lista de asistentes del evento
        List<String> updatedEventAttendees = event.attendees?.toList() ?? [];
        
        if (willAttend) {
          if (!updatedEventAttendees.contains(userId)) {
            updatedEventAttendees.add(userId);
          }
        } else {
          updatedEventAttendees.remove(userId);
        }
        
        // Actualizar el documento del evento en Firestore
        transaction.update(eventRef, {
          'attendees': updatedEventAttendees
        });
        
        // Actualizar el perfil del usuario
        List<String> userEventsAttending = [];
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          userEventsAttending = userData?['eventsAttending'] != null 
              ? List<String>.from(userData?['eventsAttending']) 
              : [];
        }
        
        if (willAttend) {
          if (!userEventsAttending.contains(eventId)) {
            userEventsAttending.add(eventId);
          }
        } else {
          userEventsAttending.remove(eventId);
        }
        
        // Actualizar el documento del usuario en Firestore
        if (userDoc.exists) {
          transaction.update(userRef, {
            'eventsAttending': userEventsAttending
          });
        } else {
          // Si por alguna razón el usuario no existe en la base de datos
          transaction.set(userRef, {
            'eventsAttending': userEventsAttending,
            'nombre': event.organizerId,
            'email': '',
            'photoUrl': null,
            'createdAt': Timestamp.now()
          });
        }
      });
      
      return;
    } catch (e) {
      print('Error al actualizar asistencia: $e');
      rethrow;
    }
  }
}

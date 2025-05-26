// filepath: d:\Proyectos_Flutter\uni_eventos_app\lib\services\event_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/event.dart';
import '/services/local_storage_service.dart';

class EventService {
  final FirebaseFirestore _firestore;
  
  EventService({
    FirebaseFirestore? firestore
  }) : _firestore = firestore ?? FirebaseFirestore.instance;
  
  // Ordenar eventos: vigentes primero (por fecha más cercana) y luego expirados
  List<Event> _sortEvents(List<Event> events) {
    final now = DateTime.now();
    final activeEvents = events.where((e) => e.date.toDate().isAfter(now)).toList();
    final expiredEvents = events.where((e) => e.date.toDate().isBefore(now)).toList();
    
    // Ordenar eventos activos por fecha más próxima primero
    activeEvents.sort((a, b) => a.date.compareTo(b.date));
    
    // Combinar eventos: primero los vigentes, luego los expirados
    return [...activeEvents, ...expiredEvents];
  }
  
  // Obtener lista de eventos desde Firestore con soporte offline
  Future<List<Event>> getEvents() async {
    try {
      // Verificar si tenemos cache reciente
      final bool hasRecentCache = await LocalStorageService.isCacheRecent();
      
      if (hasRecentCache) {
        print('Usando cache reciente de eventos');
        final events = await LocalStorageService.getCachedEvents();
        return _sortEvents(events);
      }
      
      print('Intentando cargar eventos desde Firestore...');
      // Intentar cargar desde Firestore
      final events = await Event.getEventsFromFirestore();
      
      if (events.isNotEmpty) {
        print('Eventos cargados desde Firestore: ${events.length}');
        // Si tenemos eventos, guardarlos en cache
        await LocalStorageService.cacheEvents(events);
        return _sortEvents(events);
      } else {
        print('No hay eventos en Firestore, usando cache local');
        // Si no hay eventos en Firestore, usar cache local
        final events = await LocalStorageService.getCachedEvents();
        return _sortEvents(events);
      }
    } catch (e) {
      print('Error al cargar eventos de Firestore, usando cache local: $e');
      // En caso de error (sin conexión), usar cache local
      final cachedEvents = await LocalStorageService.getCachedEvents();
      if (cachedEvents.isEmpty) {
        print('No hay cache disponible');
      } else {
        print('Usando ${cachedEvents.length} eventos del cache');
      }
      return _sortEvents(cachedEvents);
    }
  }
  
  // Forzar actualización desde Firestore
  Future<List<Event>> refreshEvents() async {
    try {
      final events = await Event.getEventsFromFirestore();
      if (events.isNotEmpty) {
        await LocalStorageService.cacheEvents(events);
      }
      return _sortEvents(events);
    } catch (e) {
      print('Error al actualizar eventos desde Firestore: $e');
      rethrow;
    }
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
      
      // Si no existe en Firestore, buscar en cache local
      final cachedEvents = await LocalStorageService.getCachedEvents();
      return cachedEvents.firstWhere(
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
      // Usar cache local como fallback
      final cachedEvents = await LocalStorageService.getCachedEvents();
      return cachedEvents
          .where((e) => e.id != currentEventId)
          .toList();
    }
  }
  
  // Verificar si hay conexión y datos en cache
  Future<bool> isOfflineMode() async {
    try {
      // Intentar una consulta simple a Firestore para verificar conectividad
      await _firestore.collection('events').limit(1).get();
      return false; // Hay conexión
    } catch (e) {
      // Sin conexión, verificar si hay cache disponible
      return await LocalStorageService.hasCache();
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
        
        // Actualizar el documento del usuario en Firestore
        if (userDoc.exists) {
          final userData = userDoc.data();
          List<String> userEventsAttending = [];
          
          if (userData != null && userData.containsKey('eventsAttending') && userData['eventsAttending'] is List) {
            userEventsAttending = List<String>.from(userData['eventsAttending']);
          }
          
          if (willAttend) {
            if (!userEventsAttending.contains(eventId)) {
              userEventsAttending.add(eventId);
            }
          } else {
            userEventsAttending.remove(eventId);
          }
          
          // Actualizar el documento del usuario
          transaction.update(userRef, {
            'eventsAttending': userEventsAttending
          });
        } else {
          // Si el usuario no existe, crear un nuevo documento para el usuario
          transaction.set(userRef, {
            'id': userId,
            'eventsAttending': willAttend ? [eventId] : []
          });
        }
      });
      
      // Actualizar cache local
      final cachedEvents = await LocalStorageService.getCachedEvents();
      for (int i = 0; i < cachedEvents.length; i++) {
        if (cachedEvents[i].id == eventId) {
          final Event oldEvent = cachedEvents[i];
          List<String> updatedAttendees = oldEvent.attendees?.toList() ?? [];
          
          if (!currentAttendingState) {
            updatedAttendees.add(userId);
          } else {
            updatedAttendees.remove(userId);
          }
          
          // No podemos modificar directamente oldEvent porque es inmutable
          // Por lo tanto, creamos una nueva instancia con los datos actualizados
          cachedEvents[i] = Event(
            id: oldEvent.id,
            title: oldEvent.title,
            imageUrl: oldEvent.imageUrl,
            date: oldEvent.date,
            location: oldEvent.location,
            description: oldEvent.description,
            organizerId: oldEvent.organizerId,
            createdAt: oldEvent.createdAt,
            category: oldEvent.category,
            capacity: oldEvent.capacity,
            attendees: updatedAttendees,
          );
          break;
        }
      }
      
      // Guardar eventos actualizados en cache
      await LocalStorageService.cacheEvents(cachedEvents);
      
    } catch (e) {
      print('Error al actualizar asistencia al evento: $e');
      throw Exception('Error al actualizar asistencia: $e');
    }
  }
  
  // Buscar eventos por categoría
  Future<List<Event>> searchEventsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('category', isEqualTo: category)
          .get();
          
      List<Event> events = snapshot.docs
          .map((doc) => Event.fromFirestore(doc))
          .toList();
          
      return _sortEvents(events);
    } catch (e) {
      // Fallback a búsqueda en caché local
      final allCachedEvents = await LocalStorageService.getCachedEvents();
      return allCachedEvents
          .where((event) => event.category == category)
          .toList();
    }
  }
  
  // Obtener un stream de eventos para actualización en tiempo real
  Stream<List<Event>> getEventsStream() {
    try {
      return Event.getEventsStream().map((events) => _sortEvents(events));
    } catch (e) {
      print('Error al obtener stream de eventos: $e');
      return Stream.value([]);
    }
  }
}

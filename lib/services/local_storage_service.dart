import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/event.dart';

class LocalStorageService {
  static const String _eventsBoxName = 'events_cache';
  static const String _metadataBoxName = 'metadata_cache';
  static const String _lastUpdateKey = 'last_update';
  static Box<Map>? _eventsBox;
  static Box<String>? _metadataBox;
  
  // Inicializar Hive
  static Future<void> initialize() async {
    await Hive.initFlutter();
    _eventsBox = await Hive.openBox<Map>(_eventsBoxName);
    _metadataBox = await Hive.openBox<String>(_metadataBoxName);
  }

  // Cerrar la base de datos
  static Future<void> close() async {
    await _eventsBox?.close();
    await _metadataBox?.close();
  }
  // Guardar eventos en cache local
  static Future<void> cacheEvents(List<Event> events) async {
    if (_eventsBox == null || _metadataBox == null) await initialize();
    
    // Limpiar cache anterior
    await _eventsBox!.clear();
    
    // Guardar eventos
    for (int i = 0; i < events.length; i++) {
      final eventMap = events[i].toJson();
      eventMap['id'] = events[i].id; // Agregar ID al mapa
      
      // Convertir Timestamp a string para almacenamiento
      if (eventMap['date'] is Timestamp) {
        eventMap['date'] = (eventMap['date'] as Timestamp).toDate().toIso8601String();
      }
      if (eventMap['createdAt'] is Timestamp) {
        eventMap['createdAt'] = (eventMap['createdAt'] as Timestamp).toDate().toIso8601String();
      }
      
      await _eventsBox!.put('event_$i', eventMap);
    }
    
    // Guardar timestamp de última actualización en la box de metadata
    await _metadataBox!.put(_lastUpdateKey, DateTime.now().toIso8601String());
  }
  // Obtener eventos del cache local
  static Future<List<Event>> getCachedEvents() async {
    if (_eventsBox == null || _metadataBox == null) await initialize();
    
    final List<Event> events = [];
    
    for (int i = 0; i < _eventsBox!.length; i++) {
      final key = 'event_$i';
      if (_eventsBox!.containsKey(key)) {
        final eventMap = Map<String, dynamic>.from(_eventsBox!.get(key)!);
        
        // Convertir strings de fecha de vuelta a Timestamp
        if (eventMap['date'] is String) {
          eventMap['date'] = Timestamp.fromDate(DateTime.parse(eventMap['date']));
        }
        if (eventMap['createdAt'] is String) {
          eventMap['createdAt'] = Timestamp.fromDate(DateTime.parse(eventMap['createdAt']));
        }
        
        final event = Event.fromJson(eventMap, id: eventMap['id']);
        events.add(event);
      }
    }
    
    return events;
  }

  // Verificar si hay datos en cache
  static Future<bool> hasCache() async {
    if (_eventsBox == null || _metadataBox == null) await initialize();
    return _eventsBox!.isNotEmpty && _metadataBox!.containsKey(_lastUpdateKey);
  }

  // Obtener timestamp de última actualización
  static Future<DateTime?> getLastUpdate() async {
    if (_metadataBox == null) await initialize();
    
    final lastUpdateStr = _metadataBox!.get(_lastUpdateKey);
    if (lastUpdateStr != null) {
      return DateTime.parse(lastUpdateStr);
    }
    return null;
  }

  // Verificar si el cache es reciente (menos de 1 hora)
  static Future<bool> isCacheRecent() async {
    final lastUpdate = await getLastUpdate();
    if (lastUpdate == null) return false;
    
    final difference = DateTime.now().difference(lastUpdate);
    return difference.inHours < 1;
  }
  // Limpiar cache
  static Future<void> clearCache() async {
    if (_eventsBox == null || _metadataBox == null) await initialize();
    await _eventsBox!.clear();
    await _metadataBox!.clear();
  }
}

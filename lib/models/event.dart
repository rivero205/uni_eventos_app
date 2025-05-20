import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String? id;
  final String title;
  final String imageUrl;
  final Timestamp date;
  final String location;
  final String description;
  final String organizerId;
  final Timestamp createdAt;
  final String? category;
  final int? capacity;
  final List<String>? attendees;

  Event({
    this.id,
    required this.title,
    required this.imageUrl,
    required this.date,
    required this.location,
    required this.description,
    required this.organizerId,
    required this.createdAt,
    this.category,
    this.capacity,
    this.attendees,
  });

  // Método para crear un mapa que Firestore pueda entender
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'date': date,
      'location': location,
      'description': description,
      'organizerId': organizerId,
      'createdAt': createdAt,
      'category': category,
      'capacity': capacity,
      'attendees': attendees,
    };
  }

  // Método para crear un objeto Event desde un DocumentSnapshot de Firestore
  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      date: data['date'] as Timestamp,
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      organizerId: data['organizerId'] ?? '',
      createdAt: data['createdAt'] as Timestamp,
      category: data['category'],
      capacity: data['capacity'],
      attendees: data['attendees'] != null 
        ? List<String>.from(data['attendees']) 
        : null,
    );
  }

  // Método para crear un objeto Event desde un mapa
  factory Event.fromJson(Map<String, dynamic> json, {String? id}) {
    return Event(
      id: id,
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      date: json['date'] as Timestamp,
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      organizerId: json['organizerId'] ?? '',
      createdAt: json['createdAt'] as Timestamp,
      category: json['category'],
      capacity: json['capacity'],
      attendees: json['attendees'] != null 
        ? List<String>.from(json['attendees']) 
        : null,
    );
  }

  // Método para crear eventos de ejemplo - mantenido por compatibilidad, pero ahora se usa desde EventService  // DEPRECATED: Método para crear eventos de ejemplo 
  // Este método es mantenido por compatibilidad pero se recomienda usar getEventsFromFirestore()
  static List<Event> getSampleEvents() {
    return [
      Event(
        id: '1',
        title: 'Arquitectura Moderna',
        imageUrl: 'https://images.unsplash.com/photo-1487958449943-2429e8be8625?q=80&w=2070',
        date: Timestamp.fromDate(DateTime(2025, 5, 15)),
        location: 'Auditorio Principal',
        description: 'Conferencia sobre las tendencias actuales en arquitectura moderna y su impacto en el diseño urbano.',
        organizerId: 'admin123',
        createdAt: Timestamp.now(),
      ),
      // Eventos reducidos para tener datos de respaldo en caso de fallo
      Event(
        id: '2',
        title: 'V Congreso',
        imageUrl: 'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?q=80&w=2012',
        date: Timestamp.fromDate(DateTime(2025, 5, 20)),
        location: 'Centro de Convenciones',
        description: 'Quinto congreso anual de innovación tecnológica con ponentes internacionales.',
        organizerId: 'admin123',
        createdAt: Timestamp.now(),
      ),
    ];
  }
  
  // Método para obtener eventos desde Firestore
  static Future<List<Event>> getEventsFromFirestore() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('events')
          .orderBy('date', descending: false)
          .get();
          
      List<Event> events = snapshot.docs
          .map((doc) => Event.fromFirestore(doc))
          .toList();
          
      // Si no hay eventos en Firestore, usar datos de ejemplo
      if (events.isEmpty) {
        return getSampleEvents();
      }
      
      return events;
    } catch (e) {
      print('Error al cargar eventos de Firestore: $e');
      // En caso de error, devolver datos de ejemplo como fallback
      return getSampleEvents();
    }
  }
}
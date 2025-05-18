// lib/models/event.dart
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

  // Método para crear eventos de ejemplo (conservado de tu código original)
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
      Event(
        id: '3',
        title: 'Ingeniería HOY',
        imageUrl: 'https://images.unsplash.com/photo-1581094794329-c8112a89af12?q=80&w=2070',
        date: Timestamp.fromDate(DateTime(2025, 5, 25)),
        location: 'Facultad de Ingeniería',
        description: 'Exposición de proyectos innovadores desarrollados por estudiantes de ingeniería.',
        organizerId: 'admin123',
        createdAt: Timestamp.now(),
      ),
      Event(
        id: '4',
        title: 'Sistemas Fotovoltaicos',
        imageUrl: 'https://images.unsplash.com/photo-1509391366360-2e959784a276?q=80&w=2072',
        date: Timestamp.fromDate(DateTime(2025, 5, 30)),
        location: 'Laboratorio de Energías',
        description: 'Taller práctico sobre instalación y mantenimiento de sistemas fotovoltaicos.',
        organizerId: 'admin123',
        createdAt: Timestamp.now(),
      ),
      Event(
        id: '5',
        title: 'Congreso',
        imageUrl: 'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?q=80&w=2070',
        date: Timestamp.fromDate(DateTime(2025, 6, 5)),
        location: 'Facultad de Ciencias',
        description: 'Presentación de avances en biotecnología aplicada a la medicina y agricultura.',
        organizerId: 'admin123',
        createdAt: Timestamp.now(),
      ),
    ];
  }
}
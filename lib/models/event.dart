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
    // Si la URL de la imagen comienza con 'assets/images/', se guarda solo el nombre del archivo.
    String finalImageUrl = imageUrl;
    if (imageUrl.startsWith('assets/images/')) {
      finalImageUrl = imageUrl.replaceFirst('assets/images/', '');
    }

    return {
      'title': title,
      'imageUrl': finalImageUrl, // Usar la URL procesada
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
    String imageUrl = data['imageUrl'] ?? '';
    
    // Asegurarse de que imageUrl siempre tenga el prefijo 'assets/images/' si no es una URL externa.
    if (!imageUrl.startsWith('http') && !imageUrl.startsWith('assets/images/')) {
      imageUrl = 'assets/images/$imageUrl';
    }
    
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      imageUrl: imageUrl, // Usar la URL procesada
      date: data['date'] as Timestamp,
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      organizerId: data['organizerId'] ?? '',
      createdAt: data['createdAt'] as Timestamp,
      category: data['category'],
      capacity: data['capacity'],      attendees: data['attendees'] != null && data['attendees'] is List
        ? List<String>.from(data['attendees']) 
        : null,
    );
  }

  // Método para crear un objeto Event desde un mapa
  factory Event.fromJson(Map<String, dynamic> json, {String? id}) {
    // Asegurarse de que imageUrl siempre tenga el prefijo 'assets/images/' si no es una URL externa.
    String imageUrl = json['imageUrl'] ?? '';
    if (!imageUrl.startsWith('http') && !imageUrl.startsWith('assets/images/')) {
      imageUrl = 'assets/images/$imageUrl';
    }
    return Event(
      id: id,
      title: json['title'] ?? '',
      imageUrl: imageUrl, // Usar la URL procesada
      date: json['date'] is String ? Timestamp.fromDate(DateTime.parse(json['date'])) : json['date'] as Timestamp,
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      organizerId: json['organizerId'] ?? '',
      createdAt: json['createdAt'] as Timestamp,
      category: json['category'],
      capacity: json['capacity'],      attendees: json['attendees'] != null && json['attendees'] is List
        ? List<String>.from(json['attendees']) 
        : null,
    );
  }
  // Método para obtener la ruta de la imagen local
  static String getLocalImagePath(String imageUrl) {
    // Esta función ya no es necesaria aquí si la lógica está en los constructores y toJson.
    // Se puede eliminar o mantener si se usa en otros lugares específicos.
    // Por ahora, la dejamos comentada o la eliminamos si no se usa.
    // if (imageUrl.startsWith('http')) {
    //   return imageUrl;
    // }
    // return 'assets/images/$imageUrl';
    return imageUrl; // Devuelve la URL como está, ya que se procesa en los constructores.
  }  // Método para obtener eventos desde Firestore
  static Future<List<Event>> getEventsFromFirestore() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('events')
          .orderBy('createdAt', descending: true) // Ordenamos por fecha de creación para obtener los más recientes primero
          .get();
          
      List<Event> events = snapshot.docs
          .map((doc) => Event.fromFirestore(doc))
          .toList();
          
      return events;
    } catch (e) {
      print('Error al cargar eventos de Firestore: $e');
      return [];
    }
  }
  
  // Método para crear un stream de eventos desde Firestore
  static Stream<List<Event>> getEventsStream() {
    try {
      return FirebaseFirestore.instance
          .collection('events')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => Event.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      print('Error al crear stream de eventos: $e');
      return Stream.value([]);
    }
  }
}
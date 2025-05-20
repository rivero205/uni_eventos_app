import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String nombre;
  final String email;
  final String? carrera;
  final String? photoUrl;
  final String? phoneNumber;
  final Timestamp? createdAt;
  final String? birthday;
  final String? instagramAccount;
  final List<String>? eventsAttending; // Lista de IDs de eventos a los que asiste

  UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    this.carrera,
    this.photoUrl,
    this.phoneNumber,
    this.createdAt,
    this.birthday,
    this.instagramAccount,
    this.eventsAttending,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      email: data['email'] ?? '',
      carrera: data['carrera'],
      photoUrl: data['photoUrl'],
      phoneNumber: data['phoneNumber'],
      createdAt: data['createdAt'],
      birthday: data['birthday'],
      instagramAccount: data['instagramAccount'],
      eventsAttending: data['eventsAttending'] != null 
        ? List<String>.from(data['eventsAttending']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'email': email,
      'carrera': carrera,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt,
      'birthday': birthday,
      'instagramAccount': instagramAccount,
      'eventsAttending': eventsAttending,
    };
  }
}

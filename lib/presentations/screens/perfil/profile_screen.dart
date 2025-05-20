import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/bottom_nav_bar.dart';
import '/models/user_model.dart';
import '/models/event.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  UserModel? _userModel;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        // Si no hay usuario autenticado, redirigir al inicio
        if (mounted) {
          context.go('/');
          return;
        }
      }

      // Obtener datos del usuario desde Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser!.uid).get();

      if (userDoc.exists) {
        setState(() {
          _userModel = UserModel.fromFirestore(userDoc);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'No se encontraron datos del usuario';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    // Mostrar diálogo de confirmación
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, cerrar sesión'),
            ),
          ],
        );
      },
    );
    
    // Proceder con el cierre de sesión si el usuario confirmó
    if (confirmLogout == true) {
      try {
        await _auth.signOut();
        if (mounted) {
          context.go('/');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0288D1),
        actions: [
          // Botón para cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildProfileContent(),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
  Widget _buildProfileContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Encabezado con color y foto de perfil
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0288D1),
                  Color(0xFF000000),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Avatar del usuario
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: _userModel?.photoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.network(
                            _userModel!.photoUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person,
                                  size: 50, color: Color(0xFF0288D1));
                            },
                          ),
                        )
                      : const Icon(Icons.person,
                          size: 50, color: Color(0xFF0288D1)),
                ),
                const SizedBox(height: 10),
                // Nombre del usuario
                Text(
                  _userModel?.nombre ?? 'Usuario',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),

          // Datos del usuario en tarjetas
          const SizedBox(height: 20),
          _buildInfoCard(
              Icons.person, 'Nombre', _userModel?.nombre ?? 'No disponible'),
          _buildInfoCard(
              Icons.email, 'Email', _userModel?.email ?? 'No disponible'),
          _buildInfoCard(
              Icons.school, 'Carrera', _userModel?.carrera ?? 'No disponible'),
          if (_userModel?.phoneNumber != null)
            _buildInfoCard(Icons.phone, 'Teléfono', _userModel!.phoneNumber!),
          if (_userModel?.birthday != null)
            _buildInfoCard(Icons.cake, 'Cumpleaños', _userModel!.birthday!),
          if (_userModel?.instagramAccount != null)
            _buildInfoCard(
                Icons.camera_alt, 'Instagram', _userModel!.instagramAccount!),
          
          // Sección de eventos a los que asiste
          const SizedBox(height: 20),
          if (_userModel?.eventsAttending != null && _userModel!.eventsAttending!.isNotEmpty)
            _buildEventsAttendingSection(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildEventsAttendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Eventos a los que asistiré',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<Event>>(
          future: _fetchAttendingEvents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar los eventos: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No estás registrado en ningún evento.'),
                ),
              );
            } else {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final event = snapshot.data![index];
                  return GestureDetector(
                    onTap: () => context.go('/event/${event.id}'),
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: [
                          // Imagen del evento
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: Image.network(
                              event.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                          ),
                          // Detalles del evento
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fecha: ${DateFormat('dd/MM/yyyy').format(event.date.toDate())}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ubicación: ${event.location}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ],
    );
  }
  
  Future<List<Event>> _fetchAttendingEvents() async {
    if (_userModel?.eventsAttending == null || _userModel!.eventsAttending!.isEmpty) {
      return [];
    }
    
    try {
      final List<Event> events = [];
      
      // Primero intentamos obtener eventos de Firestore
      for (String eventId in _userModel!.eventsAttending!) {
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
      
      // Si no encontramos eventos en Firestore, buscamos en los eventos de muestra
      if (events.isEmpty) {
        final sampleEvents = Event.getSampleEvents();
        for (String eventId in _userModel!.eventsAttending!) {
          final sampleEvent = sampleEvents.where((e) => e.id == eventId).toList();
          if (sampleEvent.isNotEmpty) {
            events.add(sampleEvent.first);
          }
        }
      }
      
      return events;
    } catch (e) {
      print('Error fetching attending events: $e');
      return [];
    }
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0288D1), size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

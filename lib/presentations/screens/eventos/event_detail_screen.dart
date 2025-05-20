import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/event.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/succes_dialog.dart';
import 'package:go_router/go_router.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Event event;
  bool isLoading = true;
  bool isAttending = false;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
  }
  Future<void> _loadEventDetails() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      Event? foundEvent;
      bool userIsAttending = false;
      
      // Primero intentamos cargar el evento desde Firestore
      try {
        final eventDoc = await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .get();
            
        if (eventDoc.exists) {
          foundEvent = Event.fromFirestore(eventDoc);
          // Verificar si el usuario está en la lista de asistentes
          userIsAttending = foundEvent.attendees?.contains(currentUser?.uid) ?? false;
        }
      } catch (firestoreError) {
        print('Error al cargar el evento desde Firestore: $firestoreError');
        // Si hay error, continuamos con eventos de muestra
      }
      
      // Si no encontramos en Firestore, usar eventos de muestra como respaldo
      if (foundEvent == null) {
        final events = Event.getSampleEvents();
        foundEvent = events.firstWhere(
          (e) => e.id == widget.eventId,
          orElse: () => throw Exception('Evento no encontrado'),
        );
        
        // Verificar si el usuario está en la lista de asistentes
        userIsAttending = foundEvent.attendees?.contains(currentUser?.uid) ?? false;
        
        // Como estamos usando un evento de muestra, vamos a verificar también si el usuario 
        // tiene este evento en su lista de eventos a los que asiste en Firestore
        if (currentUser != null) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();
                
            if (userDoc.exists) {
              final userData = userDoc.data();
              final List<String> userEventsAttending = userData?['eventsAttending'] != null 
                  ? List<String>.from(userData?['eventsAttending']) 
                  : [];
                  
              userIsAttending = userEventsAttending.contains(widget.eventId);
            }
          } catch (userError) {
            print('Error al verificar eventos del usuario: $userError');
          }
        }
      }
      
      if (mounted) {
        setState(() {
          event = foundEvent!;
          isAttending = userIsAttending;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
          // Mostrar mensaje de error con diálogo
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Error al cargar los detalles del evento: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      }
    }
  }
  Future<void> _toggleAttendance() async {
    if (isProcessing) return;
    
    setState(() {
      isProcessing = true;
    });
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('Debes iniciar sesión para asistir a eventos'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
        return;
      }
      
      // Usar una transacción para actualizar tanto el documento del evento como el del usuario
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Referencias a los documentos del evento y del usuario
        final eventRef = FirebaseFirestore.instance.collection('events').doc(widget.eventId);
        final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
        
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
        final bool willAttend = !isAttending;
        
        // Actualizar la lista de asistentes del evento
        List<String> updatedEventAttendees = event.attendees?.toList() ?? [];
        
        if (willAttend) {
          if (!updatedEventAttendees.contains(currentUser.uid)) {
            updatedEventAttendees.add(currentUser.uid);
          }
        } else {
          updatedEventAttendees.remove(currentUser.uid);
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
          if (!userEventsAttending.contains(widget.eventId)) {
            userEventsAttending.add(widget.eventId);
          }
        } else {
          userEventsAttending.remove(widget.eventId);
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
            'nombre': currentUser.displayName ?? '',
            'email': currentUser.email ?? '',
            'photoUrl': currentUser.photoURL,
            'createdAt': Timestamp.now()
          });
        }
      });
      
      // Actualizar el estado local después de la operación exitosa en la BD
      setState(() {
        isAttending = !isAttending;
        
        // Actualizar la lista de asistentes
        List<String> updatedAttendees = event.attendees?.toList() ?? [];
        
        if (isAttending) {
          if (!updatedAttendees.contains(currentUser.uid)) {
            updatedAttendees.add(currentUser.uid);
          }
        } else {
          updatedAttendees.remove(currentUser.uid);
        }
        
        // Actualizar el objeto evento con la nueva lista de asistentes
        event = Event(
          id: event.id,
          title: event.title,
          imageUrl: event.imageUrl,
          date: event.date,
          location: event.location,
          description: event.description,
          organizerId: event.organizerId,
          createdAt: event.createdAt,
          category: event.category,
          capacity: event.capacity,
          attendees: updatedAttendees,
        );
      });
      
      // Mostrar diálogo de éxito personalizado
      SuccessDialog.show(
        context: context,
        message: isAttending ? '¡Te has inscrito al evento!' : 'Has cancelado tu asistencia',
        okText: 'Aceptar',
      );
      
    } catch (e) {
      // Mostrar diálogo de error
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Error: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Formatear la fecha
    final formattedDate = DateFormat('dd/MM/yyyy - HH:mm').format(event.date.toDate());
    
    // Calcular el número de asistentes
    final attendeesCount = event.attendees?.length ?? 0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Evento'),
        elevation: 0,
        // Agregamos el botón de regreso explícitamente
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/eventos');
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del evento
            SizedBox(
              width: double.infinity,
              height: 250,
              child: Image.network(
                event.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error_outline, size: 50),
                    ),
                  );
                },
              ),
            ),
            
            // Contenido del evento
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Fecha y ubicación
                  _buildInfoRow(Icons.calendar_today, 'Fecha: $formattedDate'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.location_on, 'Ubicación: ${event.location}'),
                  
                  // Si hay categoría, mostrarla
                  if (event.category != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.category, 'Categoría: ${event.category}'),
                  ],
                  
                  // Capacidad y asistentes
                  if (event.capacity != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.people, 
                      'Asistentes: $attendeesCount/${event.capacity}',
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Descripción
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Botón para asistir/cancelar asistencia
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : _toggleAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAttending ? Colors.red : Color(0xFF0288D1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isProcessing 
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isAttending ? 'Cancelar asistencia' : 'Asistir al evento',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }
}
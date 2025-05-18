import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/event.dart';
import '../widgets/bottom_nav_bar.dart';

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
    // Para este ejemplo usaremos los eventos de muestra
    // En una aplicación real, cargaríamos el evento desde Firestore
    final events = Event.getSampleEvents();
    
    try {
      // Buscar el evento por ID en la lista de eventos de muestra
      final foundEvent = events.firstWhere(
        (e) => e.id == widget.eventId,
        orElse: () => throw Exception('Evento no encontrado'),
      );
      
      // Verificar si el usuario actual está en la lista de asistentes
      final currentUser = FirebaseAuth.instance.currentUser;
      final isUserAttending = foundEvent.attendees?.contains(currentUser?.uid) ?? false;
      
      if (mounted) {
        setState(() {
          event = foundEvent;
          isAttending = isUserAttending;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar los detalles del evento: $e'),
            backgroundColor: Colors.red,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes iniciar sesión para asistir a eventos'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Aquí iría la lógica para actualizar la asistencia en Firestore
      // Por ahora solo actualizamos el estado local
      
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAttending ? '¡Te has inscrito al evento!' : 'Has cancelado tu asistencia'),
          backgroundColor: isAttending ? Colors.green : Colors.orange,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
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
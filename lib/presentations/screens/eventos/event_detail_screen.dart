import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '/models/event.dart';
import '/services/event_service.dart';
import '/presentations/widgets/bottom_nav_bar.dart';
import '/presentations/widgets/success_dialog.dart';
import '/presentations/widgets/event/event_detail_header.dart';
import '/presentations/widgets/event/event_info_row.dart';
import '/presentations/widgets/event/attend_event_button.dart';
import '/presentations/widgets/event/related_events_list.dart';

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
  late EventService _eventService;
  late Event event;
  List<Event> relatedEvents = [];
  bool isLoading = true;
  bool isAttending = false;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _eventService = EventService();
    _loadEventDetails();
  }

  Future<void> _loadEventDetails() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      // Cargar el evento por ID
      final foundEvent = await _eventService.getEventById(widget.eventId);
      
      if (foundEvent == null) {
        throw Exception('Evento no encontrado');
      }
      
      // Verificar si el usuario está asistiendo
      bool userIsAttending = false;
      if (currentUser != null) {
        userIsAttending = await _eventService.isUserAttendingEvent(
          currentUser.uid, 
          widget.eventId
        );
      }      // Cargar eventos relacionados (excluyendo el evento actual)
      final loadedRelatedEvents = await _eventService.getRelatedEvents(widget.eventId);
      
      // Verificar que los eventos relacionados tienen ID válidos
      for (var relEvent in loadedRelatedEvents) {
        print('Evento relacionado: ${relEvent.title}, ID: ${relEvent.id}');
      }
      
      if (mounted) {
        setState(() {
          event = foundEvent;
          relatedEvents = loadedRelatedEvents;
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
    
    // Si el usuario ya está asistiendo, mostrar diálogo de confirmación antes de cancelar
    if (isAttending) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmar cancelación'),
            content: const Text('¿Estás seguro de que deseas cancelar tu asistencia a este evento?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No, mantener registro'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sí, cancelar'),
              ),
            ],
          );
        },
      );
      
      // Si el usuario cancela o cierra el diálogo, no hacer nada
      if (confirm != true) {
        return;
      }
    }
    
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
      
      // Usar el servicio para actualizar la asistencia
      await _eventService.toggleEventAttendance(
        currentUser.uid,
        widget.eventId,
        event,
        isAttending
      );
      
      // Actualizar el estado local
      final updatedAttendees = event.attendees?.toList() ?? [];
      
      if (!isAttending) {
        if (!updatedAttendees.contains(currentUser.uid)) {
          updatedAttendees.add(currentUser.uid);
        }
      } else {
        updatedAttendees.remove(currentUser.uid);
      }
      
      setState(() {
        isAttending = !isAttending;
        
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
      if (mounted) {
        SuccessDialog.show(
          context: context,
          message: isAttending ? '¡Te has inscrito al evento!' : 'Has cancelado tu asistencia',
          okText: 'Aceptar',
        );
      }
    } catch (e) {
      // Mostrar diálogo de error
      if (mounted) {
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
      }
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
            EventDetailHeader(event: event),
            
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
                  EventInfoRow(
                    icon: Icons.calendar_today,
                    text: 'Fecha: $formattedDate'
                  ),
                  const SizedBox(height: 8),
                  EventInfoRow(
                    icon: Icons.location_on,
                    text: 'Ubicación: ${event.location}'
                  ),
                  
                  // Si hay categoría, mostrarla
                  if (event.category != null) ...[
                    const SizedBox(height: 8),
                    EventInfoRow(
                      icon: Icons.category,
                      text: 'Categoría: ${event.category}'
                    ),
                  ],
                  
                  // Capacidad y asistentes
                  if (event.capacity != null) ...[
                    const SizedBox(height: 8),
                    EventInfoRow(
                      icon: Icons.people,
                      text: 'Asistentes: $attendeesCount/${event.capacity}'
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
                  AttendEventButton(
                    isAttending: isAttending,
                    isProcessing: isProcessing,
                    onPressed: _toggleAttendance,
                    isExpired: DateTime.now().isAfter(event.date.toDate()),
                  ),
                  
                  // Sección de eventos relacionados
                  RelatedEventsList(events: relatedEvents),
                ],
              ),
            ),
            
            // Espacio adicional al final
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '/models/event.dart';
import '/services/event_service.dart';
import '/presentations/widgets/bottom_nav_bar.dart';
import '/presentations/widgets/success_dialog.dart';
import '/presentations/widgets/dialogs_helper.dart';
import '/presentations/widgets/event/event_detail_header.dart';
import '/presentations/widgets/event/events_loading_widget.dart';
import '/presentations/widgets/event/event_detail_content_widget.dart';
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
      }
      
      // Cargar eventos relacionados
      final loadedRelatedEvents = await _eventService.getRelatedEvents(widget.eventId);
      
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
        
        // Mostrar mensaje de error
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Error al cargar los detalles del evento: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    }
  }
  Future<void> _toggleAttendance() async {
    if (isProcessing) return;
    
    // Si el usuario ya está asistiendo, mostrar diálogo de confirmación antes de cancelar
    if (isAttending) {
      final bool? confirm = await DialogsHelper.showConfirmationDialog(
        context: context,
        title: 'Confirmar cancelación',
        message: '¿Estás seguro de que deseas cancelar tu asistencia a este evento?',
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
        DialogsHelper.showErrorDialog(
          context: context,
          message: 'Debes iniciar sesión para asistir a eventos',
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
        DialogsHelper.showErrorDialog(
          context: context,
          message: 'Error: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }@override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: EventsLoadingWidget(),
      );
    }
    
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
            // Cabecera con imagen del evento
            EventDetailHeader(event: event),
            
            // Contenido del evento
            EventDetailContentWidget(
              event: event,
              isAttending: isAttending,
              isProcessing: isProcessing,
              onToggleAttendance: _toggleAttendance,
            ),
            
            // Eventos relacionados
            RelatedEventsList(events: relatedEvents),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}

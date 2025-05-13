import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EventoDetalleScreen extends StatelessWidget {
  final Event event;

  const EventoDetalleScreen({
    super.key, 
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Evento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen del evento
            Hero(
              tag: 'event-${event.title}',
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(event.imageUrl),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {},
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            
            // Contenido del evento en tarjeta
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Descripción
                    Text(
                      event.description ?? 'Explora la evolución de la arquitectura moderna, desde sus inicios hasta las tendencias actuales. Descubre cómo la tecnología y la sostenibilidad han influido en el diseño arquitectónico.',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Fecha
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Fecha:',
                      event.date != null 
                          ? '${event.date!.day} de ${_getMonthName(event.date!.month)} de ${event.date!.year}'
                          : '15 de abril de 2025'
                    ),
                    
                    // Hora
                    _buildInfoRow(
                      Icons.access_time,
                      'Hora:',
                      '10:00 AM - 12:00 PM'
                    ),
                    
                    // Ubicación
                    _buildInfoRow(
                      Icons.location_on,
                      'Ubicación:',
                      'Auditorio Principal Dionisio Vélez'
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botón de inscripción
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Inscripción registrada'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Inscribirse',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget para construir filas de información
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 15),
                children: [
                  TextSpan(
                    text: '$label ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper para obtener el nombre del mes
  String _getMonthName(int month) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return months[month - 1];
  }
}

// Esta clase viene del archivo original de eventos_screen.dart
class Event {
  final String title;
  final String imageUrl;
  final String? description;
  final DateTime? date;

  const Event({
    required this.title,
    required this.imageUrl,
    this.description,
    this.date,
  });
}
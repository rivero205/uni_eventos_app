import 'package:flutter/material.dart';

class AttendEventButton extends StatelessWidget {
  final bool isAttending;
  final bool isProcessing;
  final VoidCallback onPressed;
  final bool isExpired;

  const AttendEventButton({
    super.key,
    required this.isAttending,
    required this.isProcessing,
    required this.onPressed,
    this.isExpired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [        // Texto informativo sobre estado de registro o expiración
        if (isExpired)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAttending ? 'Este evento ya finalizó' : 'Este evento ya no está disponible',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (isAttending)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '¡Ya estás registrado para este evento!',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Botón de asistencia/cancelación
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (isProcessing || isExpired) ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isExpired 
                ? Colors.grey 
                : (isAttending ? Colors.red : const Color(0xFF0288D1)),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
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
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isExpired 
                        ? Icons.event_busy
                        : (isAttending ? Icons.cancel_outlined : Icons.event_available)),
                    const SizedBox(width: 8),
                    Text(
                      isExpired
                          ? 'Evento finalizado'
                          : (isAttending ? 'Cancelar asistencia' : 'Asistir al evento'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class EventsErrorMessage extends StatelessWidget {
  final String errorMessage;

  const EventsErrorMessage({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        errorMessage,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 16,
        ),
      ),
    );
  }
}

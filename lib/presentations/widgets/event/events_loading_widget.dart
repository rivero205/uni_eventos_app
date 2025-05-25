import 'package:flutter/material.dart';

class EventsLoadingWidget extends StatelessWidget {
  const EventsLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

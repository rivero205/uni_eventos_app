import 'package:flutter/material.dart';
import '/models/event.dart';
import 'related_event_card.dart';

class RelatedEventsList extends StatelessWidget {
  final List<Event> events;
  final String title;
  
  const RelatedEventsList({
    super.key, 
    required this.events,
    this.title = 'Te puede interesar',
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            itemBuilder: (context, index) => RelatedEventCard(event: events[index]),
          ),
        ],
      ),
    );
  }
}

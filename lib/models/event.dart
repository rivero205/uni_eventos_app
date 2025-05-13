class Event {
  final String id;
  final String title;
  final String imageUrl;
  final String date;
  final String location;
  final String description;

  Event({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.date,
    required this.location,
    required this.description,
  });

  // Método para crear eventos de ejemplo
  static List<Event> getSampleEvents() {
    return [
      Event(
        id: '1',
        title: 'Arquitectura Moderna',
        imageUrl: 'https://images.unsplash.com/photo-1487958449943-2429e8be8625?q=80&w=2070',
        date: '15 Mayo, 2025',
        location: 'Auditorio Principal',
        description: 'Conferencia sobre las tendencias actuales en arquitectura moderna y su impacto en el diseño urbano.',
      ),
      Event(
        id: '2',
        title: 'V Congreso',
        imageUrl: 'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?q=80&w=2012',
        date: '20 Mayo, 2025',
        location: 'Centro de Convenciones',
        description: 'Quinto congreso anual de innovación tecnológica con ponentes internacionales.',
      ),
      Event(
        id: '3',
        title: 'Ingeniería HOY',
        imageUrl: 'https://images.unsplash.com/photo-1581094794329-c8112a89af12?q=80&w=2070',
        date: '25 Mayo, 2025',
        location: 'Facultad de Ingeniería',
        description: 'Exposición de proyectos innovadores desarrollados por estudiantes de ingeniería.',
      ),
      Event(
        id: '4',
        title: 'Sistemas Fotovoltaicos',
        imageUrl: 'https://images.unsplash.com/photo-1509391366360-2e959784a276?q=80&w=2072',
        date: '30 Mayo, 2025',
        location: 'Laboratorio de Energías',
        description: 'Taller práctico sobre instalación y mantenimiento de sistemas fotovoltaicos.',
      ),
      Event(
        id: '5',
        title: 'Congreso',
        imageUrl: 'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?q=80&w=2070',
        date: '5 Junio, 2025',
        location: 'Facultad de Ciencias',
        description: 'Presentación de avances en biotecnología aplicada a la medicina y agricultura.',
      ),
    ];
  }
}

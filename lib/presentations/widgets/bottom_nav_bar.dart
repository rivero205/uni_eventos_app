import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  
  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 70, // Aumentamos la altura para acomodar texto
      color: Colors.white,
      elevation: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Eventos (Home)
          InkWell(
            onTap: () {
              if (currentIndex != 0) {
                context.go('/eventos');
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.home_outlined,
                  color: currentIndex == 0 ? Color(0xFF0288D1) : Colors.grey,
                  size: 24,
                ),
                Text(
                  'Eventos',
                  style: TextStyle(
                    color: currentIndex == 0 ? Color(0xFF0288D1) : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Mis Eventos 
          InkWell(
            onTap: () {
              if (currentIndex != 1) {
                context.go('/my-events');
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today, // Cambiado a icono de calendario
                  color: currentIndex == 1 ? Color(0xFF0288D1) : Colors.grey,
                  size: 24,
                ),
                Text(
                  'Mis Eventos',
                  style: TextStyle(
                    color: currentIndex == 1 ? Color(0xFF0288D1) : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Perfil (Nuevo)
          InkWell(
            onTap: () {
              if (currentIndex != 2) {
                context.go('/profile');
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_outline,
                  color: currentIndex == 2 ? Color(0xFF0288D1) : Colors.grey,
                  size: 24,
                ),
                Text(
                  'Perfil',
                  style: TextStyle(
                    color: currentIndex == 2 ? Color(0xFF0288D1) : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

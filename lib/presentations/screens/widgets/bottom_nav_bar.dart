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
      height: 60,
      color: Colors.white,
      elevation: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.home_outlined,
              color: currentIndex == 0 ?Color(0xFF0288D1) : Colors.grey,
            ),
            onPressed: () {
              if (currentIndex != 0) {
                context.go('/eventos');
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.person_outline,
              color: currentIndex == 1 ? Color(0xFF0288D1) : Colors.grey,
            ),
            onPressed: () {
              if (currentIndex != 1) {
                context.go('/profile');
              }
            },
          ),
        ],
      ),
    );
  }
}

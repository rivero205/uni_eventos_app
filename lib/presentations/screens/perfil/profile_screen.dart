import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/presentations/widgets/bottom_nav_bar.dart';
import '/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  UserModel? _userModel;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        // Si no hay usuario autenticado, redirigir al inicio
        if (mounted) {
          context.go('/');
          return;
        }
      }

      // Obtener datos del usuario desde Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser!.uid).get();

      if (userDoc.exists) {
        setState(() {
          _userModel = UserModel.fromFirestore(userDoc);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'No se encontraron datos del usuario';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    // Mostrar diálogo de confirmación
    bool? confirmLogout = await showDialog<bool>(
      context: context,      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              const Icon(Icons.logout, color: Color(0xFF0288D1)),
              const SizedBox(width: 10),
              const Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            '¿Estás seguro que deseas cerrar sesión?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Sí, cerrar sesión'),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
      },
    );
    
    // Proceder con el cierre de sesión si el usuario confirmó
    if (confirmLogout == true) {
      try {
        await _auth.signOut();
        if (mounted) {
          context.go('/');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0288D1),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildProfileContent(),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2), // Actualizado a índice 2
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Encabezado con color y foto de perfil
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0288D1),
                  Color(0xFF000000),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Avatar del usuario
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: _userModel?.photoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.network(
                            _userModel!.photoUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person,
                                  size: 50, color: Color(0xFF0288D1));
                            },
                          ),
                        )
                      : const Icon(Icons.person,
                          size: 50, color: Color(0xFF0288D1)),
                ),
                const SizedBox(height: 10),
                // Nombre del usuario
                Text(
                  _userModel?.nombre ?? 'Usuario',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),

          // Datos del usuario en tarjetas
          const SizedBox(height: 20),
          _buildInfoCard(
              Icons.person, 'Nombre', _userModel?.nombre ?? 'No disponible'),
          _buildInfoCard(
              Icons.email, 'Email', _userModel?.email ?? 'No disponible'),
          _buildInfoCard(
              Icons.school, 'Carrera', _userModel?.carrera ?? 'No disponible'),
          if (_userModel?.phoneNumber != null)
            _buildInfoCard(Icons.phone, 'Teléfono', _userModel!.phoneNumber!),
          if (_userModel?.birthday != null)
            _buildInfoCard(Icons.cake, 'Cumpleaños', _userModel!.birthday!),
          if (_userModel?.instagramAccount != null)
            _buildInfoCard(
                Icons.camera_alt, 'Instagram', _userModel!.instagramAccount!),
          
          const SizedBox(height: 40),
          
          // Botón de cerrar sesión
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0288D1), size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// registro_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Cloud Firestore
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart'; // Importar GoRouter
import '../../screens/widgets/succes_dialog.dart'; // Importar SuccessDialog

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _carreraController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _carreraController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _crearCuenta() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Guardar datos adicionales del usuario en Firestore
      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'nombre': _nombreController.text.trim(),
          'carrera': _carreraController.text.trim(),
          'email': _emailController.text.trim(),
          'uid': userCredential.user!.uid,
          // Puedes agregar más campos aquí, como la fecha de creación
          'createdAt': Timestamp.now(),
        });
      }

      if (mounted) {
        // Mostrar el nuevo diálogo de éxito
        SuccessDialog.show(
          context: context,
          message: 'Cuenta creada exitosamente.',
          okText: 'Aceptar',
        );
        _formKey.currentState!.reset();
        _nombreController.clear();
        _carreraController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        // Opcional: if (mounted) context.go('/');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'La contraseña proporcionada es demasiado débil.';
          break;
        case 'email-already-in-use':
          message = 'Ya existe una cuenta para ese correo electrónico.';
          break;
        case 'invalid-email':
          message = 'El formato del correo electrónico no es válido.';
          break;
        default:
          message = 'Ocurrió un error de autenticación. Inténtalo de nuevo.';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error inesperado. Por favor, inténtalo más tarde.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(
             borderRadius: BorderRadius.all(Radius.circular(4.0)),
             borderSide: BorderSide(color: Colors.black),
          ),
          focusedBorder: const OutlineInputBorder(
             borderRadius: BorderRadius.all(Radius.circular(4.0)),
             borderSide: BorderSide(color: Colors.black, width: 1.5),
          ),
          suffixIcon: suffixIcon,
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/');
          },
        ),
        
      ),
      
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Registro',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 24.0),
                _buildTextField(
                  controller: _nombreController,
                  labelText: 'Nombre completo',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, ingresa tu nombre completo';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _carreraController,
                  labelText: 'Carrera',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, ingresa tu carrera';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _emailController,
                  labelText: 'Correo',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, ingresa tu correo electrónico';
                    }
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Por favor, ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _passwordController,
                  labelText: 'Contraseña',
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa una contraseña';
                    }
                    if (value.length < 8) {
                      return 'La contraseña debe tener al menos 8 caracteres';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                _buildTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirmar Contraseña',
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16.0),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 12.0),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _crearCuenta,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white, 
                            
                          ),
                          child: const Text('CREAR CUENTA'), // Estilo de texto del tema
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

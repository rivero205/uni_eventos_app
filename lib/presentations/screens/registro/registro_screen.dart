// registro_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // <--- Eliminado

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
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  String? _errorMessage; // Puede usarse para errores generales de frontend
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

  // --- Modificado para quitar lógica de backend ---
  Future<void> _handleCrearCuentaFrontend() async {
    FocusScope.of(context).unfocus(); // Ocultar teclado

    // Validar el formulario usando las reglas definidas en cada TextFormField
    if (!_formKey.currentState!.validate()) {
      // La validación falló, los mensajes de error se mostrarán en los campos
      setState(() {
        // Opcional: Mostrar un mensaje de error general si se desea
        // _errorMessage = 'Por favor, revisa los campos marcados.';
      });
      return; // No continuar
    }

    // --- Simulación de "éxito" de frontend ---
    // Si la validación pasa, mostramos el indicador de carga
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Limpiar errores previos
    });

    // Simular un pequeño retraso (como si hubiera una llamada de red)
    await Future.delayed(const Duration(seconds: 1));

    // Acciones después de la validación "exitosa" (sin backend real)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Validación completada (simulado).',
          ), // Mensaje temporal
          backgroundColor: Colors.blue,
        ),
      );
      // Limpiar campos como demostración
      _formKey.currentState!.reset();
      _nombreController.clear();
      _carreraController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();

      // Detener el indicador de carga
      setState(() {
        _isLoading = false;
      });
      // Aquí es donde luego añadirías la llamada a Firebase u otro backend
    }
    // --- Fin de la simulación ---
  }

  // Helper para construir los campos de texto (sin cambios)
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
          labelStyle: const TextStyle(color: Colors.black54),
          suffixIcon: suffixIcon,
        ),
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // La estructura del build se mantiene igual, solo cambia la función llamada por onPressed
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            context.push('/');
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Registro',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24.0),

                // --- Campos de Texto con sus validaciones ---
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
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
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
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed:
                        () => setState(
                          () =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                        ),
                  ),
                ),

                // --- Fin de Campos de Texto ---
                const SizedBox(height: 16.0),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 12.0),

                // Botón llama a la función de frontend ahora
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                    : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // Llama a la nueva función sin backend
                        onPressed: _handleCrearCuentaFrontend,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('CREAR CUENTA'),
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

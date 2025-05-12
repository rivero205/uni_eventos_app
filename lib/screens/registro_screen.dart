// registro_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  // Controlador adicional para confirmar contraseña
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true; // Para mostrar/ocultar contraseña
  bool _obscureConfirmPassword = true; // Para mostrar/ocultar confirmación

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
    // Ocultar teclado si está abierto
    FocusScope.of(context).unfocus();

    // Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return; // Si la validación falla, no continuar
    }

    // Si la validación es exitosa, proceder con la creación de la cuenta
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Intenta crear el usuario en Firebase Auth
      // ignore: unused_local_variable
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        // Nota: Firebase Auth no guarda directamente el nombre completo o carrera
        // durante la creación. Deberás guardarlos en Firestore o Realtime Database
        // después de la creación exitosa, usando userCredential.user!.uid.
      );

      // Éxito
      if (mounted) { // Verificar si el widget sigue en el árbol
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada exitosamente.'),
            backgroundColor: Colors.green,
          ),
        );
        // Limpiar campos después del registro exitoso
        _formKey.currentState!.reset();
        _nombreController.clear();
        _carreraController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        // Opcional: Navegar a otra pantalla, por ejemplo, la de inicio de sesión o la principal
        // Navigator.of(context).pushReplacementNamed('/home');
        // Navigator.of(context).pop(); // Si esta pantalla fue 'pusheada'
      }

    } on FirebaseAuthException catch (e) {
      // Manejo de errores específicos de Firebase Auth
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
          // print('Error de Firebase Auth: ${e.code} - ${e.message}'); // Para depuración
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      // Manejo de otros errores inesperados
      setState(() {
        _errorMessage = 'Ocurrió un error inesperado. Por favor, inténtalo más tarde.';
        // print('Error general: ${e.toString()}'); // Para depuración
      });
    } finally {
      // Asegurarse de detener el indicador de carga
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper para construir los campos de texto y evitar repetición
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
          // Estilo de borde definido globalmente en ThemeData o aquí:
          border: const OutlineInputBorder(
             borderRadius: BorderRadius.all(Radius.circular(4.0)),
             borderSide: BorderSide(color: Colors.black),
          ),
          focusedBorder: const OutlineInputBorder(
             borderRadius: BorderRadius.all(Radius.circular(4.0)),
             borderSide: BorderSide(color: Colors.black, width: 1.5),
          ),
          // floatingLabelBehavior: FloatingLabelBehavior.never, // Si no quieres que la etiqueta flote
          labelStyle: const TextStyle(color: Colors.black54),
          suffixIcon: suffixIcon, // Para el botón de mostrar/ocultar contraseña
        ),
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction, // Validar mientras se escribe
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar similar a la imagen (solo flecha de regreso)
      appBar: AppBar(
        backgroundColor: Colors.white, // Fondo blanco
        elevation: 0, // Sin sombra
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Solo intentar volver si es posible (evita error si es la primera pantalla)
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      backgroundColor: Colors.white, // Fondo blanco para el cuerpo
      body: SafeArea( // Evita que el contenido se solape con áreas del sistema (notch, etc.)
        child: SingleChildScrollView( // Permite el scroll si el contenido no cabe
          padding: const EdgeInsets.all(24.0), // Espaciado alrededor del contenido
          child: Form(
            key: _formKey, // Asociar la clave global al formulario
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Alinear texto a la izquierda
              children: <Widget>[
                // Título "Registro"
                const Text(
                  'Registro',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24.0), // Espacio vertical

                // Campo Nombre completo
                _buildTextField(
                  controller: _nombreController,
                  labelText: 'Nombre completo',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, ingresa tu nombre completo';
                    }
                    return null; // Válido
                  },
                ),

                // Campo Carrera
                _buildTextField(
                  controller: _carreraController,
                  labelText: 'Carrera',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, ingresa tu carrera';
                    }
                    return null; // Válido
                  },
                ),

                // Campo Correo
                _buildTextField(
                  controller: _emailController,
                  labelText: 'Correo',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, ingresa tu correo electrónico';
                    }
                    // Validación simple de formato de email
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Por favor, ingresa un correo válido';
                    }
                    return null; // Válido
                  },
                ),

                // Campo Contraseña
                _buildTextField(
                  controller: _passwordController,
                  labelText: 'Contraseña',
                  obscureText: _obscurePassword, // Usar variable de estado
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa una contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    // Opcional: añadir más validaciones (mayúsculas, números, etc.)
                    return null; // Válido
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

                // Campo Confirmar Contraseña
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
                    return null; // Válido
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


                const SizedBox(height: 16.0), // Espacio antes del mensaje de error

                // Mostrar mensaje de error si existe
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 12.0), // Espacio antes del botón

                // Botón Crear Cuenta o Indicador de Carga
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
                    : SizedBox( // Para que el botón ocupe todo el ancho
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _crearCuenta,
                          // Estilo del botón (puede definirse globalmente en ThemeData)
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
                              )
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
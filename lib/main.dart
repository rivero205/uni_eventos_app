import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Importa Firebase Core
// import 'firebase_options.dart'; // Importa las opciones generadas por FlutterFire CLI
import 'screens/registro_screen.dart'; // Importa tu pantalla de registro

void main() async { // Haz main async
  WidgetsFlutterBinding.ensureInitialized(); // Asegura la inicialización de los bindings
  await Firebase.initializeApp( // Inicializa Firebase
  //  options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey), // Cambiado para un look más neutro
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white, // Fondo blanco por defecto
        inputDecorationTheme: const InputDecorationTheme( // Estilo para los TextFields
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
            borderSide: BorderSide(color: Colors.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
            borderSide: BorderSide(color: Colors.black, width: 1.5),
          ),
          labelStyle: TextStyle(color: Colors.black54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData( // Estilo para el botón principal
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            )
          )
        )
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'), // Comenta o elimina esto
      home: const RegistroScreen(), // Establece RegistroScreen como la pantalla inicial
      debugShowCheckedModeBanner: false,
    );
  }
}

// Puedes eliminar MyHomePage y _MyHomePageState si ya no los necesitas
// o mantenerlos para otras partes de tu app.


# UniEventos 🎓📱

Aplicación móvil desarrollada en Flutter que permite a estudiantes visualizar e inscribirse en eventos académicos. Utiliza Firebase como backend para autenticación y gestión de datos.

## 🚀 Funcionalidades

- Registro e inicio de sesión con Firebase Auth
- Visualización de eventos activos (en forma de tarjetas)
- Detalles completos del evento
- Inscripción única por usuario (guardada en Firestore)
- Control de sesión y navegación condicional

## 🛠 Tecnologías

- **Flutter & Dart** – Desarrollo móvil multiplataforma
- **Firebase Auth** – Autenticación de usuarios
- **Cloud Firestore** – Base de datos en tiempo real
- **Firebase Storage** – (opcional) para imágenes de eventos
- **Provider** – Gestión de estado

## 👨‍💻 Estructura del Proyecto

```
lib/
├── main.dart
├── models/ # Modelos de datos (Usuario, Evento, Inscripción)
├── views/ # Pantallas (Login, Registro, Eventos, Detalle)
├── controllers/ # Lógica y conexión con Firebase
├── services/ # Servicios (Auth, Eventos)
└── widgets/ # Componentes reutilizables
```
markdown
Copiar
Editar

## ✅ Requisitos Previos

- Flutter SDK instalado
- Android Studio o VS Code configurado para Flutter
- Cuenta de Firebase con un proyecto configurado
- Archivo `google-services.json` (Android) y/o `GoogleService-Info.plist` (iOS)

## 🔧 Instalación

```
git clone https://github.com/tu-usuario/unieventos.git
cd unieventos
flutter pub get
flutter run
```
📂 Integración Firebase
Crea un proyecto en Firebase Console

Habilita Firebase Auth (email/contraseña)

Crea Firestore y estructura básica de colecciones

Agrega el archivo google-services.json en android/app/

🤝 Equipo de Desarrollo
Maicol Vivero

David Mejía

Jesús Zabala

Luis Ibarra

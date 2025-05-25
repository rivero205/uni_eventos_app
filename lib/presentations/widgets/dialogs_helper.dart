import 'package:flutter/material.dart';

class DialogsHelper {
  static Future<bool?> showConfirmationDialog({
    required BuildContext context, 
    required String title,
    required String message,
    String cancelText = 'No, mantener registro',
    String confirmText = 'Sí, cancelar',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  static void showErrorDialog({
    required BuildContext context,
    required String message,
    String buttonText = 'Aceptar',
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }
}

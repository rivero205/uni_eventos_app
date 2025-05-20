import 'package:flutter/material.dart';

class SuccessDialog extends StatelessWidget {
  final String message;
  final VoidCallback? onOkPressed;
  final String okText;
  final bool barrierDismissible;

  const SuccessDialog({
    super.key,
    required this.message,
    this.onOkPressed,
    this.okText = 'OK',
    this.barrierDismissible = true,
  });

  // Método estático para mostrar el diálogo fácilmente desde cualquier parte
  static Future<void> show({
    required BuildContext context,
    required String message,
    VoidCallback? onOkPressed,
    String okText = 'OK',
    bool barrierDismissible = true,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return SuccessDialog(
          message: message,
          onOkPressed: onOkPressed,
          okText: okText,
          barrierDismissible: barrierDismissible,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Para que el diálogo sea compacto
        children: <Widget>[
          // Mensaje y checkmark
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Botón OK
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar el diálogo
              if (onOkPressed != null) {
                onOkPressed!(); // Ejecutar callback si existe
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(100, 36),
            ),
            child: Text(okText),
          ),
        ],
      ),
    );
  }
}

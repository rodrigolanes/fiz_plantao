import 'package:flutter/material.dart';

class PrimaryActionButtons extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String saveLabel;
  final String cancelLabel;
  final bool saveEnabled;

  const PrimaryActionButtons({
    super.key,
    required this.onSave,
    required this.onCancel,
    this.saveLabel = 'Salvar',
    this.cancelLabel = 'Cancelar',
    this.saveEnabled = true,
  });

  @override
  State<PrimaryActionButtons> createState() => _PrimaryActionButtonsState();
}

class _PrimaryActionButtonsState extends State<PrimaryActionButtons> {
  bool _pressed = false; // para animar apenas o Salvar

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size.fromHeight(56),
              textStyle: const TextStyle(fontSize: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(widget.cancelLabel),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Listener(
              onPointerDown: (_) => setState(() => _pressed = true),
              onPointerUp: (_) => setState(() => _pressed = false),
              onPointerCancel: (_) => setState(() => _pressed = false),
              child: ElevatedButton(
                onPressed: widget.saveEnabled ? widget.onSave : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(56),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ).copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return cs.primary.withOpacity(0.35);
                    }
                    if (states.contains(WidgetState.pressed)) {
                      return cs.primaryContainer;
                    }
                    return cs.primary;
                  }),
                  elevation: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) return 0;
                    if (states.contains(WidgetState.pressed)) return 6;
                    return 3;
                  }),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 20),
                    const SizedBox(width: 8),
                    Text(widget.saveLabel),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

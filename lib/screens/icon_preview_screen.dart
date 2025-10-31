import 'package:flutter/material.dart';
import '../widgets/app_icon_painter.dart';

class IconPreviewScreen extends StatelessWidget {
  const IconPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview do Ícone'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal[50]!,
              Colors.teal[100]!,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Ícone do Aplicativo',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Versão com fundo (iOS/Web)',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                const AppIconPreview(size: 250),
                const SizedBox(height: 48),
                const Text(
                  'Versão adaptativa (Android)',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(55),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(55)),
                    child: AdaptiveAppIcon(size: 250),
                  ),
                ),
                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 24),
                const Text(
                  'Tamanhos de Preview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: [
                    _IconSizePreview(size: 48, label: '48x48'),
                    _IconSizePreview(size: 72, label: '72x72'),
                    _IconSizePreview(size: 96, label: '96x96'),
                    _IconSizePreview(size: 144, label: '144x144'),
                    _IconSizePreview(size: 192, label: '192x192'),
                  ],
                ),
                const SizedBox(height: 48),
                Card(
                  color: Colors.teal[700],
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Ícone Estilizado',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Design vetorial escalável com:\n'
                          '• Planta em vaso estilizada\n'
                          '• Gradientes modernos\n'
                          '• Otimizado para múltiplas resoluções\n'
                          '• Suporte a ícones adaptativos Android',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
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

class _IconSizePreview extends StatelessWidget {
  final double size;
  final String label;

  const _IconSizePreview({
    required this.size,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppIconPreview(size: size),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

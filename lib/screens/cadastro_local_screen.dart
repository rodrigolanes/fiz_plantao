import 'package:flutter/material.dart';
import '../models/local.dart';

class CadastroLocalScreen extends StatefulWidget {
  final Local? local;

  const CadastroLocalScreen({super.key, this.local});

  @override
  State<CadastroLocalScreen> createState() => _CadastroLocalScreenState();
}

class _CadastroLocalScreenState extends State<CadastroLocalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apelidoController = TextEditingController();
  final _nomeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.local != null) {
      _apelidoController.text = widget.local!.apelido;
      _nomeController.text = widget.local!.nome;
    }
  }

  @override
  void dispose() {
    _apelidoController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      final agora = DateTime.now();
      final local = Local(
        id: widget.local?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        apelido: _apelidoController.text,
        nome: _nomeController.text,
        criadoEm: widget.local?.criadoEm ?? agora,
        atualizadoEm: agora,
      );

      Navigator.of(context).pop(local);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.local != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? 'Editar Local' : 'Novo Local'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _apelidoController,
              decoration: const InputDecoration(
                labelText: 'Apelido',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
                helperText: 'Nome curto para identificação rápida',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe o apelido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome Completo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
                helperText: 'Nome completo do local',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe o nome completo';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Cancelar'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _salvar,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Salvar'),
                    ),
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

import 'package:flutter/material.dart';
import '../models/local.dart';
import '../services/database_service.dart';
import 'cadastro_local_screen.dart';

class ListaLocaisScreen extends StatefulWidget {
  const ListaLocaisScreen({super.key});

  @override
  State<ListaLocaisScreen> createState() => _ListaLocaisScreenState();
}

class _ListaLocaisScreenState extends State<ListaLocaisScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _carregarLocais() {
    setState(() {});
  }

  Future<void> _navegarParaCadastro([Local? local]) async {
    final resultado = await Navigator.of(context).push<Local>(
      MaterialPageRoute(
        builder: (context) => CadastroLocalScreen(local: local),
      ),
    );

    if (resultado != null && mounted) {
      await DatabaseService.saveLocal(resultado);
      _carregarLocais();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              local == null ? 'Local cadastrado com sucesso!' : 'Local atualizado com sucesso!',
            ),
          ),
        );
      }
    }
  }

  void _confirmarExclusao(Local local) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir o local "${local.apelido}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseService.deleteLocal(local.id);
              Navigator.of(context).pop();
              _carregarLocais();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Local excluído com sucesso!')),
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final ativos = DatabaseService.getLocaisAtivos();
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Não precisa mais retornar lista - dados estão no Hive
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Locais'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ativos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum local cadastrado',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Clique no botão + para adicionar',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ativos.length,
              itemBuilder: (context, index) {
                final local = ativos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        local.apelido.isNotEmpty ? local.apelido[0].toUpperCase() : 'L',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      local.apelido,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(local.nome),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _navegarParaCadastro(local),
                          tooltip: 'Editar',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmarExclusao(local),
                          tooltip: 'Excluir',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navegarParaCadastro(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

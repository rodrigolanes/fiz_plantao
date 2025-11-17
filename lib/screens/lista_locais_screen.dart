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
  bool _mostrarInativos = false;

  @override
  void initState() {
    super.initState();
  }

  void _carregarLocais() {
    setState(() {});
  }

  Future<void> _navegarParaCadastro([Local? local]) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final resultado = await navigator.push<Local>(
      MaterialPageRoute(
        builder: (_) => CadastroLocalScreen(local: local),
      ),
    );
    if (!mounted) return;
    if (resultado != null) {
      await DatabaseService.instance.saveLocal(resultado);
      if (!mounted) return;
      _carregarLocais();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            local == null ? 'Local cadastrado com sucesso!' : 'Local atualizado com sucesso!',
          ),
        ),
      );
    }
  }

  void _confirmarExclusao(Local local) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir o local "${local.apelido}"?'),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              navigator.pop();
              try {
                await DatabaseService.instance.deleteLocal(local.id);
                if (!mounted) return;
                _carregarLocais();
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Local excluído com sucesso!')),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao excluir local'),
                    backgroundColor: Colors.red,
                  ),
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
    final locais = DatabaseService.instance.getLocaisAtivos();
    final inativos = DatabaseService.instance.getAllLocais().where((l) => !l.ativo).toList();
    final locaisExibidos = _mostrarInativos ? [...locais, ...inativos] : locais;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Não precisa mais retornar lista - dados estão no Hive
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Locais'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: Icon(_mostrarInativos ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _mostrarInativos = !_mostrarInativos;
                });
              },
              tooltip: _mostrarInativos ? 'Ocultar inativos' : 'Mostrar inativos',
            ),
          ],
        ),
        body: locaisExibidos.isEmpty
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
                itemCount: locaisExibidos.length,
                itemBuilder: (context, index) {
                  final local = locaisExibidos[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: local.ativo ? null : Colors.grey[200],
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            local.ativo ? Theme.of(context).colorScheme.primaryContainer : Colors.grey[400],
                        child: Text(
                          local.apelido.isNotEmpty ? local.apelido[0].toUpperCase() : 'L',
                          style: TextStyle(
                            color: local.ativo ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              local.apelido,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: local.ativo ? null : Colors.grey[600],
                              ),
                            ),
                          ),
                          if (!local.ativo)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Inativo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        local.nome,
                        style: TextStyle(
                          color: local.ativo ? null : Colors.grey[600],
                        ),
                      ),
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

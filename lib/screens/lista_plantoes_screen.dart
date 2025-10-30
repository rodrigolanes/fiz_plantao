import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plantao.dart';
import '../models/local.dart';
import 'cadastro_plantao_screen.dart';
import 'lista_locais_screen.dart';

class ListaPlantoesScreen extends StatefulWidget {
  const ListaPlantoesScreen({super.key});

  @override
  State<ListaPlantoesScreen> createState() => _ListaPlantoesScreenState();
}

class _ListaPlantoesScreenState extends State<ListaPlantoesScreen> {
  final List<Plantao> _plantoes = [];
  final List<Local> _locais = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _gerenciarLocais() async {
    final listaAtualizada = await Navigator.of(context).push<List<Local>>(
      MaterialPageRoute(
        builder: (context) => ListaLocaisScreen(locaisIniciais: _locais),
      ),
    );
    if (listaAtualizada != null && mounted) {
      setState(() {
        _locais
          ..clear()
          ..addAll(listaAtualizada);
        // Se algum plantão referenciava local inativo/removido, filtramos logicamente
        for (var i = 0; i < _plantoes.length; i++) {
          final p = _plantoes[i];
          final localAtivo = _locais.any((l) => l.id == p.local.id && l.ativo);
          if (!localAtivo) {
            _plantoes[i] = p.copyWith(ativo: false, atualizadoEm: DateTime.now());
          }
        }
      });
    }
  }

  String _formatarDataHora(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  String _formatarData(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatarValor(double valor) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor);
  }

  Future<void> _navegarParaCadastro([Plantao? plantao]) async {
    final ativos = _locais.where((l) => l.ativo).toList();
    if (ativos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre um local ativo antes de criar um plantão.')),
      );
      return; // FAB já está desabilitado, mas proteção adicional
    }
    final resultado = await Navigator.of(context).push<Plantao>(
      MaterialPageRoute(
        builder: (context) => CadastroPlantaoScreen(
          plantao: plantao,
          locais: ativos,
        ),
      ),
    );

    if (resultado != null && mounted) {
      setState(() {
        if (plantao == null) {
          // Novo plantão
          _plantoes.add(resultado);
        } else {
          // Edição
          final index = _plantoes.indexWhere((p) => p.id == plantao.id);
          if (index != -1) {
            _plantoes[index] = resultado;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            plantao == null
                ? 'Plantão cadastrado com sucesso!'
                : 'Plantão atualizado com sucesso!',
          ),
        ),
      );
    }
  }

  void _confirmarExclusao(Plantao plantao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja realmente excluir o plantão em ${plantao.local.apelido}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final index = _plantoes.indexWhere((p) => p.id == plantao.id);
                if (index != -1) {
                  final atual = _plantoes[index];
                  _plantoes[index] = atual.copyWith(
                    ativo: false,
                    atualizadoEm: DateTime.now(),
                  );
                }
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plantão excluído com sucesso!')),
              );
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(DateTime previsaoPagamento) {
    final hoje = DateTime.now();
    final diferenca = previsaoPagamento.difference(hoje).inDays;

    if (diferenca < 0) {
      return Colors.red; // Atrasado
    } else if (diferenca <= 7) {
      return Colors.orange; // Próximo
    } else {
      return Colors.green; // No prazo
    }
  }

  @override
  Widget build(BuildContext context) {
    final locaisAtivos = _locais.where((l) => l.ativo).toList();
    final plantoesAtivos = _plantoes.where((p) => p.ativo && p.local.ativo).toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Plantões'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: (plantoesAtivos.isEmpty)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    locaisAtivos.isEmpty ? Icons.location_off : Icons.medical_services_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    locaisAtivos.isEmpty ? 'Nenhum local cadastrado' : 'Nenhum plantão cadastrado',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locaisAtivos.isEmpty
                        ? 'Crie seu primeiro local para cadastrar plantões.'
                        : 'Clique no botão + para adicionar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (locaisAtivos.isEmpty)
                    ElevatedButton.icon(
                      onPressed: _gerenciarLocais,
                      icon: const Icon(Icons.add_location_alt),
                      label: const Text('Cadastrar Local'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plantoesAtivos.length,
              itemBuilder: (context, index) {
                final plantao = plantoesAtivos[index];
                final statusColor = _getStatusColor(plantao.previsaoPagamento);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _navegarParaCadastro(plantao),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plantao.local.apelido,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      plantao.local.nome,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _navegarParaCadastro(plantao),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmarExclusao(plantao),
                                tooltip: 'Excluir',
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _formatarDataHora(plantao.dataHora),
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                plantao.duracao.label,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      _formatarValor(plantao.valor),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_month,
                                      size: 14,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatarData(plantao.previsaoPagamento),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: locaisAtivos.isEmpty ? null : () => _navegarParaCadastro(),
        backgroundColor: locaisAtivos.isEmpty ? Colors.grey[300] : null,
        foregroundColor: locaisAtivos.isEmpty ? Colors.grey[500] : null,
        icon: const Icon(Icons.add),
        label: const Text('Novo Plantão'),
      ),
    );
  }
}

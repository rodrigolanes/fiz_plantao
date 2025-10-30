import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plantao.dart';
import '../models/local.dart';
import 'cadastro_plantao_screen.dart';

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
    _inicializarLocais();
  }

  void _inicializarLocais() {
    // Locais de exemplo (posteriormente virão do banco de dados)
    _locais.addAll([
      Local(
        id: '1',
        apelido: 'HSL',
        nome: 'Hospital São Lucas',
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      ),
      Local(
        id: '2',
        apelido: 'HGE',
        nome: 'Hospital Geral do Estado',
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      ),
      Local(
        id: '3',
        apelido: 'UPA Centro',
        nome: 'UPA 24h Centro',
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      ),
    ]);
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
    final resultado = await Navigator.of(context).push<Plantao>(
      MaterialPageRoute(
        builder: (context) => CadastroPlantaoScreen(
          plantao: plantao,
          locais: _locais,
        ),
      ),
    );

    if (resultado != null && mounted) {
      setState(() {
        if (plantao == null) {
          // Novo plantão
          _plantoes.add(resultado);
          _plantoes.sort((a, b) => b.dataHora.compareTo(a.dataHora));
        } else {
          // Edição
          final index = _plantoes.indexWhere((p) => p.id == plantao.id);
          if (index != -1) {
            _plantoes[index] = resultado;
            _plantoes.sort((a, b) => b.dataHora.compareTo(a.dataHora));
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
                _plantoes.removeWhere((p) => p.id == plantao.id);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Plantões'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _plantoes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum plantão cadastrado',
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
              itemCount: _plantoes.length,
              itemBuilder: (context, index) {
                final plantao = _plantoes[index];
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
                                    const Icon(Icons.attach_money, size: 16),
                                    const SizedBox(width: 8),
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
                                  color: statusColor.withOpacity(0.2),
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
        onPressed: () => _navegarParaCadastro(),
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
    );
  }
}

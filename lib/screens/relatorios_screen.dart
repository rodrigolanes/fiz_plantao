import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/plantao.dart';
import '../services/database_service.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  bool _apenasProximos = true;

  String _formatarValor(double valor) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(valor);
  }

  Map<String, List<Plantao>> _agruparPorLocal(List<Plantao> plantoes) {
    final Map<String, List<Plantao>> agrupados = {};

    for (final plantao in plantoes) {
      final key = plantao.local.id;
      if (!agrupados.containsKey(key)) {
        agrupados[key] = [];
      }
      agrupados[key]!.add(plantao);
    }

    return agrupados;
  }

  List<Plantao> _filtrarPlantoes(List<Plantao> plantoes) {
    if (!_apenasProximos) return plantoes;

    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);

    return plantoes.where((p) {
      final previsao = DateTime(
        p.previsaoPagamento.year,
        p.previsaoPagamento.month,
        p.previsaoPagamento.day,
      );
      return previsao.isAtSameMomentAs(inicioDia) || previsao.isAfter(inicioDia);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final todosPlantoes = DatabaseService.getPlantoesAtivos();
    final plantoesFiltrados = _filtrarPlantoes(todosPlantoes);
    final plantoesPorLocal = _agruparPorLocal(plantoesFiltrados);

    // Calcular totais
    double totalGeral = 0;
    int quantidadeGeral = 0;

    for (final plantoes in plantoesPorLocal.values) {
      for (final plantao in plantoes) {
        totalGeral += plantao.valor;
        quantidadeGeral++;
      }
    }

    // Ordenar locais por valor total (decrescente)
    final locaisOrdenados = plantoesPorLocal.entries.toList()
      ..sort((a, b) {
        final totalA = a.value.fold<double>(0, (sum, p) => sum + p.valor);
        final totalB = b.value.fold<double>(0, (sum, p) => sum + p.valor);
        return totalB.compareTo(totalA);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Filtro
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal[50],
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _apenasProximos ? 'Exibindo apenas pagamentos futuros' : 'Exibindo todos os plantões',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.teal[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Switch(
                      value: _apenasProximos,
                      onChanged: (value) {
                        setState(() {
                          _apenasProximos = value;
                        });
                      },
                      activeColor: Colors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Apenas pagamentos futuros',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Card de totais gerais
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal[700]!, Colors.teal[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Geral',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$quantidadeGeral plantões',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatarValor(totalGeral),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de locais
          Expanded(
            child: plantoesPorLocal.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assessment_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum plantão encontrado',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _apenasProximos
                              ? 'Nenhum pagamento futuro registrado'
                              : 'Cadastre plantões para ver os relatórios',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: locaisOrdenados.length,
                    itemBuilder: (context, index) {
                      final entry = locaisOrdenados[index];
                      final plantoes = entry.value;
                      final local = plantoes.first.local;

                      final quantidade = plantoes.length;
                      final total = plantoes.fold<double>(
                        0,
                        (sum, p) => sum + p.valor,
                      );
                      final percentual = (total / totalGeral * 100);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal[100],
                            child: Text(
                              local.apelido.isNotEmpty ? local.apelido[0].toUpperCase() : 'L',
                              style: TextStyle(
                                color: Colors.teal[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            local.apelido,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '$quantidade plantões',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: percentual / 100,
                                        minHeight: 6,
                                        backgroundColor: Colors.grey[200],
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.teal[400],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${percentual.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Text(
                            _formatarValor(total),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          children: [
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildMetricaCard(
                                        'Valor Médio',
                                        _formatarValor(total / quantidade),
                                        Icons.payments_outlined,
                                      ),
                                      _buildMetricaCard(
                                        'Quantidade',
                                        quantidade.toString(),
                                        Icons.event_outlined,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Plantões por Data de Pagamento',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._buildPlantoesPorPagamento(plantoes),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPlantoesPorPagamento(List<Plantao> plantoes) {
    // Agrupar plantões por data de pagamento
    final Map<String, List<Plantao>> plantoesPorData = {};

    for (final plantao in plantoes) {
      final dataPagamento = DateFormat('dd/MM/yyyy', 'pt_BR').format(plantao.previsaoPagamento);
      if (!plantoesPorData.containsKey(dataPagamento)) {
        plantoesPorData[dataPagamento] = [];
      }
      plantoesPorData[dataPagamento]!.add(plantao);
    }

    // Ordenar por data de pagamento
    final datasOrdenadas = plantoesPorData.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('dd/MM/yyyy', 'pt_BR').parse(a);
        final dateB = DateFormat('dd/MM/yyyy', 'pt_BR').parse(b);
        return dateA.compareTo(dateB);
      });

    return datasOrdenadas.map((dataPagamento) {
      final plantoesDaData = plantoesPorData[dataPagamento]!;
      final totalData = plantoesDaData.fold<double>(0, (sum, p) => sum + p.valor);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.teal[700]),
                    const SizedBox(width: 8),
                    Text(
                      dataPagamento,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatarValor(totalData),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...plantoesDaData.map((plantao) {
              return Padding(
                padding: const EdgeInsets.only(left: 24, top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(plantao.dataHora),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Text(
                      _formatarValor(plantao.valor),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildMetricaCard(String label, String valor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.teal[700]),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
        ],
      ),
    );
  }
}

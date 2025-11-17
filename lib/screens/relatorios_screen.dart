import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../models/plantao.dart';
import '../services/database_service.dart';
import '../services/log_service.dart';
import '../services/pdf_service.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  bool _apenasProximos = true;
  String _filtroPagamento = 'todos'; // 'todos', 'pagos', 'pendentes'
  String? _localExpandido; // ID do local com card expandido (para exportação individual)

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
    // Filtro de tempo
    List<Plantao> filtrados = plantoes;
    if (_apenasProximos) {
      final hoje = DateTime.now();
      final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);

      filtrados = filtrados.where((p) {
        final previsao = DateTime(
          p.previsaoPagamento.year,
          p.previsaoPagamento.month,
          p.previsaoPagamento.day,
        );
        return previsao.isAtSameMomentAs(inicioDia) || previsao.isAfter(inicioDia);
      }).toList();
    }

    // Filtro de pagamento
    if (_filtroPagamento == 'pagos') {
      filtrados = filtrados.where((p) => p.pago).toList();
    } else if (_filtroPagamento == 'pendentes') {
      filtrados = filtrados.where((p) => !p.pago).toList();
    }

    return filtrados;
  }

  @override
  Widget build(BuildContext context) {
    final todosPlantoes = DatabaseService.instance.getPlantoesAtivos();
    final plantoesFiltrados = _filtrarPlantoes(todosPlantoes);
    final plantoesPorLocal = _agruparPorLocal(plantoesFiltrados);

    // Calcular totais
    double totalGeral = 0;
    double totalPago = 0;
    double totalPendente = 0;
    int quantidadeGeral = 0;
    int quantidadePagos = 0;
    int quantidadePendentes = 0;

    for (final plantoes in plantoesPorLocal.values) {
      for (final plantao in plantoes) {
        totalGeral += plantao.valor;
        quantidadeGeral++;
        if (plantao.pago) {
          totalPago += plantao.valor;
          quantidadePagos++;
        } else {
          totalPendente += plantao.valor;
          quantidadePendentes++;
        }
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar PDF',
            onSelected: (value) async {
              if (value == 'todos') {
                await _exportarPdf(null, plantoesFiltrados);
              } else if (value == 'local' && _localExpandido != null) {
                await _exportarPdf(_localExpandido, plantoesFiltrados);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'todos',
                child: Row(
                  children: [
                    Icon(Icons.list_alt, size: 20),
                    SizedBox(width: 12),
                    Text('Exportar Todos Locais'),
                  ],
                ),
              ),
              if (_localExpandido != null)
                PopupMenuItem(
                  value: 'local',
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Exportar Local Selecionado',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Colors.teal[700]),
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
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Apenas futuros',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Switch(
                          value: _apenasProximos,
                          onChanged: (value) {
                            setState(() {
                              _apenasProximos = value;
                            });
                          },
                          activeThumbColor: Colors.teal,
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text(
                  'Status de Pagamento',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: 'todos',
                            label: Text('Todos'),
                            icon: Icon(Icons.all_inclusive, size: 16),
                          ),
                          ButtonSegment<String>(
                            value: 'pagos',
                            label: Text('Pagos'),
                            icon: Icon(Icons.check_circle, size: 16),
                          ),
                          ButtonSegment<String>(
                            value: 'pendentes',
                            label: Text('Pendentes'),
                            icon: Icon(Icons.pending, size: 16),
                          ),
                        ],
                        selected: {_filtroPagamento},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _filtroPagamento = newSelection.first;
                          });
                        },
                      ),
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
                  color: Colors.teal.withValues(alpha: 0.3),
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$quantidadeGeral ${quantidadeGeral == 1 ? 'plantão' : 'plantões'}',
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
                if (_filtroPagamento == 'todos' && (quantidadePagos > 0 || quantidadePendentes > 0)) ...[
                  const Divider(color: Colors.white54, height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white70, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Pagos ($quantidadePagos)',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatarValor(totalPago),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.pending, color: Colors.white70, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Pendentes ($quantidadePendentes)',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatarValor(totalPendente),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
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
                          onExpansionChanged: (isExpanded) {
                            setState(() {
                              _localExpandido = isExpanded ? local.id : null;
                            });
                          },
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$quantidade ${quantidade == 1 ? 'plantão' : 'plantões'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
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
      final todosPagos = plantoesDaData.every((p) => p.pago);
      final algumPago = plantoesDaData.any((p) => p.pago);

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
                Expanded(
                  child: Row(
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
                ),
                Row(
                  children: [
                    Text(
                      _formatarValor(totalData),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: todosPagos,
                        onChanged: (value) async {
                          await _confirmarMarcarPagamentoData(
                            dataPagamento,
                            plantoesDaData,
                            value,
                          );
                        },
                        activeThumbColor: Colors.green[600],
                        thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Icon(Icons.check, color: Colors.white);
                          }
                          return null;
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (algumPago && !todosPagos)
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4),
                child: Text(
                  'Alguns plantões já foram pagos',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            ...plantoesDaData.map((plantao) {
              return Padding(
                padding: const EdgeInsets.only(left: 24, top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(plantao.dataHora),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: plantao.pago ? Colors.green[50] : Colors.orange[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: plantao.pago ? Colors.green[300]! : Colors.orange[300]!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          plantao.pago ? 'Pago' : 'Pendente',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: plantao.pago ? Colors.green[800] : Colors.orange[800],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        _formatarValor(plantao.valor),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
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

  Future<void> _exportarPdf(String? localId, List<Plantao> plantoes) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Mostrar loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Gerando PDF...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Preparar filtros
      final filtros = {
        'apenasProximos': _apenasProximos,
        'filtroPagamento': _filtroPagamento,
      };

      // Gerar PDF
      final pdfBytes = await PdfService.generateRelatorioPorLocal(
        plantoes,
        localId,
        filtros,
      );

      if (!mounted) return;

      // Fechar loading dialog
      navigator.pop();

      // Nome do arquivo
      final dataHora = DateFormat('yyyy-MM-dd_HHmmss', 'pt_BR').format(DateTime.now());
      final nomeLocal =
          localId != null ? plantoes.firstWhere((p) => p.local.id == localId).local.apelido : 'todos-locais';
      final filename = 'relatorio-plantoes-$nomeLocal-$dataHora.pdf';

      // Compartilhar/baixar PDF usando printing package
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: filename,
      );

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('PDF exportado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      LogService.ui('Erro ao exportar relatório', e);
      if (!mounted) return;

      // Fechar loading dialog
      navigator.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao exportar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmarMarcarPagamentoData(
    String dataPagamento,
    List<Plantao> plantoes,
    bool marcarComoPago,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final quantidadeAfetados =
        marcarComoPago ? plantoes.where((p) => !p.pago).length : plantoes.where((p) => p.pago).length;

    if (quantidadeAfetados == 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            marcarComoPago ? 'Todos os plantões já estão marcados como pagos' : 'Nenhum plantão está marcado como pago',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              marcarComoPago ? Icons.check_circle : Icons.cancel,
              color: marcarComoPago ? Colors.green[600] : Colors.orange[700],
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Confirmar Ação')),
          ],
        ),
        content: Text(
          marcarComoPago
              ? 'Deseja marcar $quantidadeAfetados plantão(ões) com previsão de pagamento em $dataPagamento como PAGOS?'
              : 'Deseja desmarcar $quantidadeAfetados plantão(ões) com previsão de pagamento em $dataPagamento como NÃO PAGOS?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => navigator.pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: marcarComoPago ? Colors.green[600] : Colors.orange[700],
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    if (!mounted) return;

    try {
      // Atualizar todos os plantões da data
      for (final plantao in plantoes) {
        if (plantao.pago != marcarComoPago) {
          final plantaoAtualizado = plantao.copyWith(
            pago: marcarComoPago,
            atualizadoEm: DateTime.now(),
          );
          await DatabaseService.instance.savePlantao(plantaoAtualizado);
        }
      }

      if (!mounted) return;

      setState(() {});

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            marcarComoPago
                ? '$quantidadeAfetados plantão(ões) marcado(s) como pago(s)'
                : '$quantidadeAfetados plantão(ões) desmarcado(s)',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      LogService.ui('Erro ao exportar relatório', e);
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar plantões: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

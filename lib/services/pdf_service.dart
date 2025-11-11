import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/plantao.dart';

class PdfService {
  /// Gera PDF do relatório de plantões
  ///
  /// [plantoes] - Lista de plantões para incluir no relatório
  /// [localId] - Se null, inclui todos os locais. Se String, filtra por local específico
  /// [filtros] - Map com configurações: 'apenasProximos' (bool), 'filtroPagamento' (String)
  static Future<Uint8List> generateRelatorioPorLocal(
    List<Plantao> plantoes,
    String? localId,
    Map<String, dynamic> filtros,
  ) async {
    final pdf = pw.Document();

    // Filtrar plantões se localId foi especificado
    final plantoesFiltrados = localId == null ? plantoes : plantoes.where((p) => p.local.id == localId).toList();

    // Agrupar por local
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

    // Criar página do PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Cabeçalho
          _buildHeader(filtros, localId, plantoesPorLocal),
          pw.SizedBox(height: 20),

          // Card de totais
          _buildTotaisCard(
            totalGeral: totalGeral,
            totalPago: totalPago,
            totalPendente: totalPendente,
            quantidadeGeral: quantidadeGeral,
            quantidadePagos: quantidadePagos,
            quantidadePendentes: quantidadePendentes,
            filtroPagamento: filtros['filtroPagamento'] as String,
          ),
          pw.SizedBox(height: 20),

          // Tabela resumo por local
          _buildTabelaResumo(locaisOrdenados, totalGeral),
          pw.SizedBox(height: 20),

          // Detalhamento por local
          ...locaisOrdenados.map((entry) {
            final plantoes = entry.value;
            final local = plantoes.first.local;
            return _buildDetalheLocal(local.apelido, plantoes);
          }),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    return pdf.save();
  }

  static Map<String, List<Plantao>> _agruparPorLocal(List<Plantao> plantoes) {
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

  static pw.Widget _buildHeader(
    Map<String, dynamic> filtros,
    String? localId,
    Map<String, List<Plantao>> plantoesPorLocal,
  ) {
    final dataGeracao = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(DateTime.now());
    final apenasProximos = filtros['apenasProximos'] as bool;
    final filtroPagamento = filtros['filtroPagamento'] as String;

    String tituloFiltro = 'Todos os Plantões';
    if (localId != null && plantoesPorLocal.isNotEmpty) {
      final nomeLocal = plantoesPorLocal.values.first.first.local.apelido;
      tituloFiltro = 'Local: $nomeLocal';
    }

    String subtituloFiltro = apenasProximos ? 'Apenas pagamentos futuros' : 'Todos os períodos';
    if (filtroPagamento == 'pagos') {
      subtituloFiltro += ' • Apenas pagos';
    } else if (filtroPagamento == 'pendentes') {
      subtituloFiltro += ' • Apenas pendentes';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Relatório de Plantões',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.teal800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          tituloFiltro,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          subtituloFiltro,
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Gerado em: $dataGeracao',
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey500,
          ),
        ),
        pw.Divider(thickness: 2, color: PdfColors.teal),
      ],
    );
  }

  static pw.Widget _buildTotaisCard({
    required double totalGeral,
    required double totalPago,
    required double totalPendente,
    required int quantidadeGeral,
    required int quantidadePagos,
    required int quantidadePendentes,
    required String filtroPagamento,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.teal200, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Geral',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal800,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal100,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  '$quantidadeGeral plantões',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal800,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            _formatarValor(totalGeral),
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal800,
            ),
          ),
          if (filtroPagamento == 'todos' && (quantidadePagos > 0 || quantidadePendentes > 0)) ...[
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.teal200),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Pagos ($quantidadePagos)',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _formatarValor(totalPago),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Pendentes ($quantidadePendentes)',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _formatarValor(totalPendente),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildTabelaResumo(
    List<MapEntry<String, List<Plantao>>> locaisOrdenados,
    double totalGeral,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Resumo por Local',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.teal50),
              children: [
                _buildTableCell('Local', isHeader: true),
                _buildTableCell('Qtd', isHeader: true, alignment: pw.Alignment.center),
                _buildTableCell('Total', isHeader: true, alignment: pw.Alignment.centerRight),
                _buildTableCell('Média', isHeader: true, alignment: pw.Alignment.centerRight),
                _buildTableCell('%', isHeader: true, alignment: pw.Alignment.center),
              ],
            ),
            // Dados
            ...locaisOrdenados.map((entry) {
              final plantoes = entry.value;
              final local = plantoes.first.local;
              final quantidade = plantoes.length;
              final total = plantoes.fold<double>(0, (sum, p) => sum + p.valor);
              final media = total / quantidade;
              final percentual = (total / totalGeral * 100).toStringAsFixed(1);

              return pw.TableRow(
                children: [
                  _buildTableCell(local.apelido),
                  _buildTableCell(quantidade.toString(), alignment: pw.Alignment.center),
                  _buildTableCell(_formatarValor(total), alignment: pw.Alignment.centerRight),
                  _buildTableCell(_formatarValor(media), alignment: pw.Alignment.centerRight),
                  _buildTableCell('$percentual%', alignment: pw.Alignment.center),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.teal800 : PdfColors.grey800,
        ),
      ),
    );
  }

  static pw.Widget _buildDetalheLocal(String nomeLocal, List<Plantao> plantoes) {
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

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: const pw.BoxDecoration(
            color: PdfColors.teal700,
          ),
          child: pw.Text(
            nomeLocal,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        ...datasOrdenadas.map((dataPagamento) {
          final plantoesDaData = plantoesPorData[dataPagamento]!;
          final totalData = plantoesDaData.fold<double>(0, (sum, p) => sum + p.valor);

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Pagamento: $dataPagamento',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.Text(
                      _formatarValor(totalData),
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal700,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                ...plantoesDaData.map((plantao) {
                  final dataHora = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(plantao.dataHora);
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8, top: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Row(
                          children: [
                            if (plantao.pago)
                              pw.Container(
                                width: 10,
                                height: 10,
                                margin: const pw.EdgeInsets.only(right: 4),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.green600,
                                  shape: pw.BoxShape.circle,
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    '✓',
                                    style: const pw.TextStyle(
                                      fontSize: 7,
                                      color: PdfColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            pw.Text(
                              dataHora,
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: plantao.pago ? PdfColors.grey500 : PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                        pw.Text(
                          _formatarValor(plantao.valor),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: plantao.pago ? PdfColors.grey500 : PdfColors.grey800,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey600,
        ),
      ),
    );
  }

  static String _formatarValor(double valor) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(valor);
  }
}

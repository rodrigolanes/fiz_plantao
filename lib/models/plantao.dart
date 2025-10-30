import 'local.dart';

enum Duracao {
  dozeHoras('12h'),
  vinteQuatroHoras('24h');

  final String label;
  const Duracao(this.label);
}

class Plantao {
  final String id;
  final Local local;
  final DateTime dataHora;
  final Duracao duracao;
  final double valor;
  final DateTime previsaoPagamento;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  Plantao({
    required this.id,
    required this.local,
    required this.dataHora,
    required this.duracao,
    required this.valor,
    required this.previsaoPagamento,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  Plantao copyWith({
    String? id,
    Local? local,
    DateTime? dataHora,
    Duracao? duracao,
    double? valor,
    DateTime? previsaoPagamento,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return Plantao(
      id: id ?? this.id,
      local: local ?? this.local,
      dataHora: dataHora ?? this.dataHora,
      duracao: duracao ?? this.duracao,
      valor: valor ?? this.valor,
      previsaoPagamento: previsaoPagamento ?? this.previsaoPagamento,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}

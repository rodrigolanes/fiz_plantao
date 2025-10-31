import 'package:hive/hive.dart';
import 'local.dart';

part 'plantao.g.dart';

@HiveType(typeId: 2)
enum Duracao {
  @HiveField(0)
  dozeHoras('12h'),
  @HiveField(1)
  vinteQuatroHoras('24h');

  final String label;
  const Duracao(this.label);
}

@HiveType(typeId: 1)
class Plantao {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final Local local;
  @HiveField(2)
  final DateTime dataHora;
  @HiveField(3)
  final Duracao duracao;
  @HiveField(4)
  final double valor;
  @HiveField(5)
  final DateTime previsaoPagamento;
  @HiveField(6)
  final DateTime criadoEm;
  @HiveField(7)
  final DateTime atualizadoEm;
  @HiveField(8)
  final bool ativo; // soft delete flag

  Plantao({
    required this.id,
    required this.local,
    required this.dataHora,
    required this.duracao,
    required this.valor,
    required this.previsaoPagamento,
    required this.criadoEm,
    required this.atualizadoEm,
    this.ativo = true,
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
    bool? ativo,
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
      ativo: ativo ?? this.ativo,
    );
  }
}

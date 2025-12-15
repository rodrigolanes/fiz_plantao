import 'package:hive/hive.dart';

import 'local.dart';

part 'plantao.g.dart';

@HiveType(typeId: 2)
enum Duracao {
  @HiveField(2)
  seisHoras('6h', 6),
  @HiveField(0)
  dozeHoras('12h', 12),
  @HiveField(1)
  vinteQuatroHoras('24h', 24);

  final String label;
  final int hours;
  const Duracao(this.label, this.hours);
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
  @HiveField(9)
  final String userId; // ID do usuário proprietário
  @HiveField(10)
  final bool pago; // Indica se o plantão foi pago
  @HiveField(11)
  final String? calendarEventId; // ID do evento do plantão no Google Calendar
  @HiveField(12)
  final String? calendarPaymentEventId; // ID do evento de pagamento no Google Calendar (obsoleto, agora é por data)
  @HiveField(13)
  final DateTime? deletadoEm; // Timestamp do soft delete

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
    required this.userId,
    this.pago = false,
    this.calendarEventId,
    this.calendarPaymentEventId,
    this.deletadoEm,
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
    String? userId,
    bool? pago,
    String? calendarEventId,
    String? calendarPaymentEventId,
    DateTime? deletadoEm,
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
      userId: userId ?? this.userId,
      pago: pago ?? this.pago,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      calendarPaymentEventId: calendarPaymentEventId ?? this.calendarPaymentEventId,
      deletadoEm: deletadoEm ?? this.deletadoEm,
    );
  }
}

import 'package:hive/hive.dart';

part 'local.g.dart';

@HiveType(typeId: 0)
class Local {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String apelido;
  @HiveField(2)
  final String nome;
  @HiveField(3)
  final DateTime criadoEm;
  @HiveField(4)
  final DateTime atualizadoEm;
  @HiveField(5)
  final bool ativo; // soft delete flag
  @HiveField(6)
  final String userId; // ID do usuário proprietário

  Local({
    required this.id,
    required this.apelido,
    required this.nome,
    required this.criadoEm,
    required this.atualizadoEm,
    this.ativo = true,
    required this.userId,
  });

  Local copyWith({
    String? id,
    String? apelido,
    String? nome,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    bool? ativo,
    String? userId,
  }) {
    return Local(
      id: id ?? this.id,
      apelido: apelido ?? this.apelido,
      nome: nome ?? this.nome,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      ativo: ativo ?? this.ativo,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() => apelido;
}

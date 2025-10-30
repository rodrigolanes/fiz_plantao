class Local {
  final String id;
  final String apelido;
  final String nome;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  Local({
    required this.id,
    required this.apelido,
    required this.nome,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  Local copyWith({
    String? id,
    String? apelido,
    String? nome,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return Local(
      id: id ?? this.id,
      apelido: apelido ?? this.apelido,
      nome: nome ?? this.nome,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  @override
  String toString() => apelido;
}

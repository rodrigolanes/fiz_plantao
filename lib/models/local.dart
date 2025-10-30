class Local {
  final String id;
  final String apelido;
  final String nome;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final bool ativo; // soft delete flag

  Local({
    required this.id,
    required this.apelido,
    required this.nome,
    required this.criadoEm,
    required this.atualizadoEm,
    this.ativo = true,
  });

  Local copyWith({
    String? id,
    String? apelido,
    String? nome,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    bool? ativo,
  }) {
    return Local(
      id: id ?? this.id,
      apelido: apelido ?? this.apelido,
      nome: nome ?? this.nome,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      ativo: ativo ?? this.ativo,
    );
  }

  @override
  String toString() => apelido;
}

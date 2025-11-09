import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/local.dart';
import '../models/plantao.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'log_service.dart';

/// Serviço para gerar massa de dados para testes
/// IMPORTANTE: Só executa em modo debug e precisa ter userId
class TestDataService {
  static const _uuid = Uuid();
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Gera uma massa de dados para testes
  static Future<void> generateTestData() async {
    // Só executa em modo debug
    if (!kDebugMode) return;

    final userId = AuthService.userId;
    if (userId == null) return;

    // Remove dados existentes do usuário (local e remoto)
    final locaisBox = DatabaseService.locaisBox;
    final plantoesBox = DatabaseService.plantoesBox;

    // Deletar plantões locais do usuário
    final plantoesParaDeletar = plantoesBox.values.where((p) => p.userId == userId).map((p) => p.id).toList();

    for (final id in plantoesParaDeletar) {
      await plantoesBox.delete(id);
    }

    // Deletar locais locais do usuário
    final locaisParaDeletar = locaisBox.values.where((l) => l.userId == userId).map((l) => l.id).toList();

    for (final id in locaisParaDeletar) {
      await locaisBox.delete(id);
    }

    // Deletar plantões remotos do usuário
    try {
      await _supabase.from('plantoes').delete().eq('user_id', userId);
      LogService.sync('Plantões remotos deletados para usuário $userId');
    } catch (e) {
      LogService.sync('Erro ao deletar plantões remotos', e);
    }

    // Deletar locais remotos do usuário
    try {
      await _supabase.from('locais').delete().eq('user_id', userId);
      LogService.sync('Locais remotos deletados para usuário $userId');
    } catch (e) {
      LogService.sync('Erro ao deletar locais remotos', e);
    }

    // Cria locais de teste
    final hospitalA = Local(
      id: _uuid.v4(),
      nome: 'Hospital São Lucas',
      apelido: 'São Lucas',
      userId: userId,
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    final hospitalB = Local(
      id: _uuid.v4(),
      nome: 'Hospital Santa Casa de Misericórdia',
      apelido: 'Santa Casa',
      userId: userId,
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    final clinica = Local(
      id: _uuid.v4(),
      nome: 'Clínica Médica Central',
      apelido: 'Central',
      userId: userId,
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    await locaisBox.putAll({
      hospitalA.id: hospitalA,
      hospitalB.id: hospitalB,
      clinica.id: clinica,
    });

    // Data base para os plantões (30 dias atrás)
    final hoje = DateTime.now();
    final inicio = DateTime(hoje.year, hoje.month - 1, hoje.day);

    // Cria plantões para cada local
    final plantoes = <String, Plantao>{};

    // Hospital A - Plantões passados (pagos)
    for (var i = 0; i < 5; i++) {
      final dataHora = inicio.add(Duration(days: i * 2));
      final plantao = Plantao(
        id: _uuid.v4(),
        local: hospitalA,
        dataHora: dataHora,
        duracao: i % 2 == 0 ? Duracao.dozeHoras : Duracao.vinteQuatroHoras,
        valor: i % 2 == 0 ? 1200.0 : 2400.0,
        previsaoPagamento: dataHora.add(const Duration(days: 30)),
        pago: true,
        criadoEm: dataHora,
        atualizadoEm: dataHora,
        userId: userId,
      );
      plantoes[plantao.id] = plantao;
    }

    // Hospital B - Plantões mistos (alguns pagos)
    for (var i = 0; i < 5; i++) {
      final dataHora = inicio.add(Duration(days: i * 3 + 10));
      final plantao = Plantao(
        id: _uuid.v4(),
        local: hospitalB,
        dataHora: dataHora,
        duracao: i % 2 == 0 ? Duracao.dozeHoras : Duracao.vinteQuatroHoras,
        valor: i % 2 == 0 ? 1500.0 : 3000.0,
        previsaoPagamento: dataHora.add(const Duration(days: 45)),
        pago: i < 3, // Primeiros pagos, últimos pendentes
        criadoEm: dataHora,
        atualizadoEm: dataHora,
        userId: userId,
      );
      plantoes[plantao.id] = plantao;
    }

    // Clínica - Plantões futuros (pendentes)
    for (var i = 0; i < 5; i++) {
      final dataHora = hoje.add(Duration(days: i + 1));
      final plantao = Plantao(
        id: _uuid.v4(),
        local: clinica,
        dataHora: dataHora,
        duracao: Duracao.dozeHoras,
        valor: 800.0,
        previsaoPagamento: dataHora.add(const Duration(days: 15)),
        pago: false,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
        userId: userId,
      );
      plantoes[plantao.id] = plantao;
    }

    await plantoesBox.putAll(plantoes);
  }
}

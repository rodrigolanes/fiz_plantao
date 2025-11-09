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
    final hsl = Local(
      id: _uuid.v4(),
      nome: 'Hospital São Lucas',
      apelido: 'HSL',
      userId: userId,
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    final cticor = Local(
      id: _uuid.v4(),
      nome: 'CTICor',
      apelido: 'CTICor',
      userId: userId,
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    final hmhs = Local(
      id: _uuid.v4(),
      nome: 'Hospital da Mulher Heloneida Studart',
      apelido: 'HMHS',
      userId: userId,
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    await locaisBox.putAll({
      hsl.id: hsl,
      cticor.id: cticor,
      hmhs.id: hmhs,
    });

    // Data base para os plantões - hoje é 08/11/2025
    final hoje = DateTime(2025, 11, 8);

    // Cria plantões para cada local
    final plantoes = <String, Plantao>{};

    // HSL - Plantões 12h às 07:00 (passado e futuro, mistos)
    // Pagamento: sem data específica, varia
    final datasHSL = [
      DateTime(2025, 10, 15, 7, 0), // Passado
      DateTime(2025, 10, 28, 7, 0), // Passado
      DateTime(2025, 11, 5, 7, 0), // Passado recente
      DateTime(2025, 11, 12, 7, 0), // Futuro próximo
      DateTime(2025, 11, 20, 7, 0), // Futuro
      DateTime(2025, 12, 3, 7, 0), // Futuro distante
    ];

    for (var i = 0; i < datasHSL.length; i++) {
      final dataHora = datasHSL[i];
      final pagamentoDia = dataHora.add(Duration(days: 30 + (i * 3))); // Varia

      final plantao = Plantao(
        id: _uuid.v4(),
        local: hsl,
        dataHora: dataHora,
        duracao: Duracao.dozeHoras,
        valor: 1200.0,
        previsaoPagamento: DateTime(pagamentoDia.year, pagamentoDia.month, pagamentoDia.day, 0, 0),
        pago: dataHora.isBefore(hoje) && i < 2, // Apenas os 2 primeiros do passado estão pagos
        criadoEm: dataHora.isBefore(hoje) ? dataHora : hoje,
        atualizadoEm: dataHora.isBefore(hoje) ? dataHora : hoje,
        userId: userId,
      );
      plantoes[plantao.id] = plantao;
    }

    // CTICor - Plantões 24h às 19:00 (passado e futuro)
    // Pagamento: dia 25 do mês
    final datasCTICor = [
      DateTime(2025, 10, 10, 19, 0), // Passado
      DateTime(2025, 10, 22, 19, 0), // Passado
      DateTime(2025, 11, 2, 19, 0), // Passado recente
      DateTime(2025, 11, 14, 19, 0), // Futuro próximo
      DateTime(2025, 11, 26, 19, 0), // Futuro
    ];

    for (var i = 0; i < datasCTICor.length; i++) {
      final dataHora = datasCTICor[i];

      // Pagamento sempre no dia 25 do mês seguinte ao plantão
      final mesPagamento = dataHora.month == 12 ? 1 : dataHora.month + 1;
      final anoPagamento = dataHora.month == 12 ? dataHora.year + 1 : dataHora.year;
      final previsaoPagamento = DateTime(anoPagamento, mesPagamento, 25, 0, 0);

      final plantao = Plantao(
        id: _uuid.v4(),
        local: cticor,
        dataHora: dataHora,
        duracao: Duracao.vinteQuatroHoras,
        valor: 2400.0,
        previsaoPagamento: previsaoPagamento,
        pago: dataHora.isBefore(hoje) && i == 0, // Apenas o primeiro do passado está pago
        criadoEm: dataHora.isBefore(hoje) ? dataHora : hoje,
        atualizadoEm: dataHora.isBefore(hoje) ? dataHora : hoje,
        userId: userId,
      );
      plantoes[plantao.id] = plantao;
    }

    // HMHS - Plantões 12h alternando 07:00 e 19:00 (passado e futuro)
    // Pagamento: dia 20 do mês
    final datasHMHS = [
      DateTime(2025, 10, 8, 7, 0), // Passado
      DateTime(2025, 10, 18, 19, 0), // Passado
      DateTime(2025, 10, 30, 7, 0), // Passado
      DateTime(2025, 11, 10, 19, 0), // Futuro próximo
      DateTime(2025, 11, 18, 7, 0), // Futuro
      DateTime(2025, 11, 28, 19, 0), // Futuro
    ];

    for (var i = 0; i < datasHMHS.length; i++) {
      final dataHora = datasHMHS[i];

      // Pagamento sempre no dia 20 do mês seguinte ao plantão
      final mesPagamento = dataHora.month == 12 ? 1 : dataHora.month + 1;
      final anoPagamento = dataHora.month == 12 ? dataHora.year + 1 : dataHora.year;
      final previsaoPagamento = DateTime(anoPagamento, mesPagamento, 20, 0, 0);

      final plantao = Plantao(
        id: _uuid.v4(),
        local: hmhs,
        dataHora: dataHora,
        duracao: Duracao.dozeHoras,
        valor: 800.0,
        previsaoPagamento: previsaoPagamento,
        pago: dataHora.isBefore(hoje) && i < 1, // Apenas o primeiro do passado está pago
        criadoEm: dataHora.isBefore(hoje) ? dataHora : hoje,
        atualizadoEm: dataHora.isBefore(hoje) ? dataHora : hoje,
        userId: userId,
      );
      plantoes[plantao.id] = plantao;
    }

    await plantoesBox.putAll(plantoes);
  }
}

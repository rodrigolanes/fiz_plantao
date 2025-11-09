import 'dart:io';

import 'package:fizplantao/models/local.dart';
import 'package:fizplantao/models/plantao.dart';
import 'package:fizplantao/services/auth_service.dart';
import 'package:fizplantao/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  group('DatabaseService - Plantão Sorting', () {
    late Directory hiveTempDir;
    late Box<Local> locaisBox;
    late Box<Plantao> plantoesBox;
    late Local localTeste;
    final userId = 'test-user-123';

    setUpAll(() async {
      // Inicializa bindings de teste
      TestWidgetsFlutterBinding.ensureInitialized();
      // Inicializa Hive em diretório temporário sem depender de plugins
      hiveTempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(hiveTempDir.path);

      // Registra os adapters se ainda não estiverem registrados
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(LocalAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PlantaoAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(DuracaoAdapter());
      }
    });

    tearDownAll(() async {
      try {
        if (hiveTempDir.existsSync()) {
          await hiveTempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    setUp(() async {
      // Garante boxes padrão usados pelo DatabaseService
      if (!Hive.isBoxOpen('locais')) {
        locaisBox = await Hive.openBox<Local>('locais');
      } else {
        locaisBox = Hive.box<Local>('locais');
      }
      if (!Hive.isBoxOpen('plantoes')) {
        plantoesBox = await Hive.openBox<Plantao>('plantoes');
      } else {
        plantoesBox = Hive.box<Plantao>('plantoes');
      }

      // Mock do AuthService.userId
      AuthService.userId = userId;

      // Cria um local de teste
      final agora = DateTime.now();
      localTeste = Local(
        id: 'local-test',
        apelido: 'HSL',
        nome: 'Hospital São Lucas',
        criadoEm: agora,
        atualizadoEm: agora,
        userId: userId,
      );
    });

    tearDown(() async {
      // Limpa os boxes após cada teste
      await locaisBox.clear();
      await plantoesBox.clear();
    });

    test('getPlantoesAtivos deve ordenar por data do mais antigo para o mais novo', () async {
      final agora = DateTime.now();

      // Cria plantões em datas diferentes
      final plantao1 = Plantao(
        id: 'plantao-1',
        local: localTeste,
        dataHora: agora.subtract(const Duration(days: 10)), // Mais antigo
        duracao: Duracao.dozeHoras,
        valor: 1200.0,
        previsaoPagamento: agora.add(const Duration(days: 20)),
        criadoEm: agora,
        atualizadoEm: agora,
        userId: userId,
      );

      final plantao2 = Plantao(
        id: 'plantao-2',
        local: localTeste,
        dataHora: agora.add(const Duration(days: 5)), // Futuro próximo
        duracao: Duracao.dozeHoras,
        valor: 1200.0,
        previsaoPagamento: agora.add(const Duration(days: 35)),
        criadoEm: agora,
        atualizadoEm: agora,
        userId: userId,
      );

      final plantao3 = Plantao(
        id: 'plantao-3',
        local: localTeste,
        dataHora: agora.subtract(const Duration(days: 5)), // Passado recente
        duracao: Duracao.dozeHoras,
        valor: 1200.0,
        previsaoPagamento: agora.add(const Duration(days: 25)),
        criadoEm: agora,
        atualizadoEm: agora,
        userId: userId,
      );

      final plantao4 = Plantao(
        id: 'plantao-4',
        local: localTeste,
        dataHora: agora.add(const Duration(days: 15)), // Mais futuro
        duracao: Duracao.vinteQuatroHoras,
        valor: 2400.0,
        previsaoPagamento: agora.add(const Duration(days: 45)),
        criadoEm: agora,
        atualizadoEm: agora,
        userId: userId,
      );

      // Adiciona os plantões fora de ordem cronológica
      await plantoesBox.put(plantao2.id, plantao2);
      await plantoesBox.put(plantao1.id, plantao1);
      await plantoesBox.put(plantao4.id, plantao4);
      await plantoesBox.put(plantao3.id, plantao3);

      // Obtém a lista ordenada
      final plantoesOrdenados = DatabaseService.getPlantoesAtivos();

      // Verifica que retornou todos os 4 plantões
      expect(plantoesOrdenados.length, 4);

      // Verifica a ordem: do mais antigo para o mais novo
      expect(plantoesOrdenados[0].id, 'plantao-1'); // -10 dias
      expect(plantoesOrdenados[1].id, 'plantao-3'); // -5 dias
      expect(plantoesOrdenados[2].id, 'plantao-2'); // +5 dias
      expect(plantoesOrdenados[3].id, 'plantao-4'); // +15 dias

      // Verifica que a ordenação é crescente
      for (int i = 0; i < plantoesOrdenados.length - 1; i++) {
        expect(
          plantoesOrdenados[i].dataHora.isBefore(plantoesOrdenados[i + 1].dataHora) ||
              plantoesOrdenados[i].dataHora.isAtSameMomentAs(plantoesOrdenados[i + 1].dataHora),
          true,
          reason: 'Plantão $i deve ser anterior ou igual ao plantão ${i + 1}',
        );
      }
    });

    test('getPlantoesAtivos deve ordenar corretamente plantões na mesma data', () async {
      final agora = DateTime.now();
      final mesmaData = DateTime(2025, 11, 15);

      // Cria plantões na mesma data, mas horários diferentes
      final plantao1 = Plantao(
        id: 'plantao-1',
        local: localTeste,
        dataHora: DateTime(mesmaData.year, mesmaData.month, mesmaData.day, 8, 0), // 08:00
        duracao: Duracao.dozeHoras,
        valor: 1200.0,
        previsaoPagamento: agora.add(const Duration(days: 30)),
        criadoEm: agora,
        atualizadoEm: agora,
        userId: userId,
      );

      final plantao2 = Plantao(
        id: 'plantao-2',
        local: localTeste,
        dataHora: DateTime(mesmaData.year, mesmaData.month, mesmaData.day, 20, 0), // 20:00
        duracao: Duracao.dozeHoras,
        valor: 1200.0,
        previsaoPagamento: agora.add(const Duration(days: 30)),
        criadoEm: agora,
        atualizadoEm: agora,
        userId: userId,
      );

      final plantao3 = Plantao(
        id: 'plantao-3',
        local: localTeste,
        dataHora: DateTime(mesmaData.year, mesmaData.month, mesmaData.day, 14, 0), // 14:00
        duracao: Duracao.dozeHoras,
        valor: 1200.0,
        previsaoPagamento: agora.add(const Duration(days: 30)),
        criadoEm: agora,
        atualizadoEm: agora,
        userId: userId,
      );

      // Adiciona os plantões fora de ordem
      await plantoesBox.put(plantao2.id, plantao2);
      await plantoesBox.put(plantao1.id, plantao1);
      await plantoesBox.put(plantao3.id, plantao3);

      // Obtém a lista ordenada
      final plantoesOrdenados = DatabaseService.getPlantoesAtivos();

      // Verifica a ordem por horário
      expect(plantoesOrdenados.length, 3);
      expect(plantoesOrdenados[0].id, 'plantao-1'); // 08:00
      expect(plantoesOrdenados[1].id, 'plantao-3'); // 14:00
      expect(plantoesOrdenados[2].id, 'plantao-2'); // 20:00
    });

    test('getPlantoesAtivos deve incluir apenas plantões ativos', () async {
      final agora = DateTime.now();

      final plantaoAtivo = Plantao(
        id: 'plantao-ativo',
        local: localTeste,
        dataHora: agora,
        duracao: Duracao.dozeHoras,
        valor: 1200.0,
        previsaoPagamento: agora.add(const Duration(days: 30)),
        criadoEm: agora,
        atualizadoEm: agora,
        ativo: true,
        userId: userId,
      );

      final plantaoInativo = Plantao(
        id: 'plantao-inativo',
        local: localTeste,
        dataHora: agora.subtract(const Duration(days: 1)),
        duracao: Duracao.dozeHoras,
        valor: 1200.0,
        previsaoPagamento: agora.add(const Duration(days: 29)),
        criadoEm: agora,
        atualizadoEm: agora,
        ativo: false,
        userId: userId,
      );

      await plantoesBox.put(plantaoAtivo.id, plantaoAtivo);
      await plantoesBox.put(plantaoInativo.id, plantaoInativo);

      final plantoesOrdenados = DatabaseService.getPlantoesAtivos();

      // Deve retornar apenas o plantão ativo
      expect(plantoesOrdenados.length, 1);
      expect(plantoesOrdenados[0].id, 'plantao-ativo');
      expect(plantoesOrdenados[0].ativo, true);
    });
  });
}

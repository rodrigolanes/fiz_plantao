import 'package:fizplantao/models/local.dart';
import 'package:fizplantao/models/plantao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Duracao Enum', () {
    test('deve ter valores corretos', () {
      expect(Duracao.values.length, 3);
      expect(Duracao.values, contains(Duracao.seisHoras));
      expect(Duracao.values, contains(Duracao.dozeHoras));
      expect(Duracao.values, contains(Duracao.vinteQuatroHoras));
    });

    test('deve ter labels corretos', () {
      expect(Duracao.seisHoras.label, '6h');
      expect(Duracao.dozeHoras.label, '12h');
      expect(Duracao.vinteQuatroHoras.label, '24h');
    });

    test('deve ter hours corretos', () {
      expect(Duracao.seisHoras.hours, 6);
      expect(Duracao.dozeHoras.hours, 12);
      expect(Duracao.vinteQuatroHoras.hours, 24);
    });

    test('deve permitir busca por name', () {
      final duracao6 = Duracao.values.firstWhere((d) => d.name == 'seisHoras');
      final duracao12 = Duracao.values.firstWhere((d) => d.name == 'dozeHoras');
      final duracao24 = Duracao.values.firstWhere((d) => d.name == 'vinteQuatroHoras');

      expect(duracao6, Duracao.seisHoras);
      expect(duracao12, Duracao.dozeHoras);
      expect(duracao24, Duracao.vinteQuatroHoras);
    });
  });

  group('Plantao Model', () {
    late DateTime agora;
    late Local localTeste;
    late Plantao plantaoTeste;

    setUp(() {
      agora = DateTime.now();
      localTeste = Local(
        id: 'local-123',
        apelido: 'HSL',
        nome: 'Hospital São Lucas',
        criadoEm: agora,
        atualizadoEm: agora,
        userId: 'user-456',
      );

      plantaoTeste = Plantao(
        id: 'plantao-789',
        local: localTeste,
        dataHora: agora,
        duracao: Duracao.dozeHoras,
        valor: 1200.0,
        previsaoPagamento: agora.add(const Duration(days: 30)),
        criadoEm: agora,
        atualizadoEm: agora,
        ativo: true,
        userId: 'user-456',
        pago: false,
      );
    });

    group('Construtor', () {
      test('deve criar Plantao com todos os campos obrigatórios', () {
        expect(plantaoTeste.id, 'plantao-789');
        expect(plantaoTeste.local, localTeste);
        expect(plantaoTeste.dataHora, agora);
        expect(plantaoTeste.duracao, Duracao.dozeHoras);
        expect(plantaoTeste.valor, 1200.0);
        expect(plantaoTeste.previsaoPagamento, agora.add(const Duration(days: 30)));
        expect(plantaoTeste.criadoEm, agora);
        expect(plantaoTeste.atualizadoEm, agora);
        expect(plantaoTeste.ativo, true);
        expect(plantaoTeste.userId, 'user-456');
        expect(plantaoTeste.pago, false);
      });

      test('deve criar Plantao com ativo = true por padrão', () {
        final plantao = Plantao(
          id: 'plantao-111',
          local: localTeste,
          dataHora: agora,
          duracao: Duracao.vinteQuatroHoras,
          valor: 2400.0,
          previsaoPagamento: agora.add(const Duration(days: 45)),
          criadoEm: agora,
          atualizadoEm: agora,
          userId: 'user-456',
        );

        expect(plantao.ativo, true);
      });

      test('deve criar Plantao com pago = false por padrão', () {
        final plantao = Plantao(
          id: 'plantao-222',
          local: localTeste,
          dataHora: agora,
          duracao: Duracao.dozeHoras,
          valor: 1500.0,
          previsaoPagamento: agora.add(const Duration(days: 30)),
          criadoEm: agora,
          atualizadoEm: agora,
          userId: 'user-456',
        );

        expect(plantao.pago, false);
      });

      test('deve criar Plantao de 24 horas', () {
        final plantao24h = Plantao(
          id: 'plantao-24h',
          local: localTeste,
          dataHora: agora,
          duracao: Duracao.vinteQuatroHoras,
          valor: 2400.0,
          previsaoPagamento: agora.add(const Duration(days: 30)),
          criadoEm: agora,
          atualizadoEm: agora,
          userId: 'user-456',
        );

        expect(plantao24h.duracao, Duracao.vinteQuatroHoras);
        expect(plantao24h.duracao.label, '24h');
      });
    });

    group('copyWith', () {
      test('deve criar cópia com campos alterados', () {
        final novaData = agora.add(const Duration(days: 1));
        final plantaoAtualizado = plantaoTeste.copyWith(
          dataHora: novaData,
          valor: 1500.0,
        );

        expect(plantaoAtualizado.id, plantaoTeste.id);
        expect(plantaoAtualizado.dataHora, novaData);
        expect(plantaoAtualizado.valor, 1500.0);
        expect(plantaoAtualizado.local, plantaoTeste.local);
        expect(plantaoAtualizado.duracao, plantaoTeste.duracao);
      });

      test('deve manter campos originais quando não especificados', () {
        final plantaoCopia = plantaoTeste.copyWith();

        expect(plantaoCopia.id, plantaoTeste.id);
        expect(plantaoCopia.local, plantaoTeste.local);
        expect(plantaoCopia.dataHora, plantaoTeste.dataHora);
        expect(plantaoCopia.duracao, plantaoTeste.duracao);
        expect(plantaoCopia.valor, plantaoTeste.valor);
        expect(plantaoCopia.previsaoPagamento, plantaoTeste.previsaoPagamento);
        expect(plantaoCopia.criadoEm, plantaoTeste.criadoEm);
        expect(plantaoCopia.atualizadoEm, plantaoTeste.atualizadoEm);
        expect(plantaoCopia.ativo, plantaoTeste.ativo);
        expect(plantaoCopia.userId, plantaoTeste.userId);
        expect(plantaoCopia.pago, plantaoTeste.pago);
      });

      test('deve permitir alterar ativo para false (soft delete)', () {
        final plantaoInativado = plantaoTeste.copyWith(ativo: false);

        expect(plantaoInativado.ativo, false);
        expect(plantaoInativado.id, plantaoTeste.id);
      });

      test('deve permitir marcar como pago', () {
        final plantaoPago = plantaoTeste.copyWith(pago: true);

        expect(plantaoPago.pago, true);
        expect(plantaoPago.id, plantaoTeste.id);
      });

      test('deve permitir desmarcar pagamento', () {
        final plantaoPago = plantaoTeste.copyWith(pago: true);
        final plantaoNaoPago = plantaoPago.copyWith(pago: false);

        expect(plantaoNaoPago.pago, false);
      });

      test('deve permitir alterar local', () {
        final novoLocal = Local(
          id: 'local-999',
          apelido: 'HC',
          nome: 'Hospital Central',
          criadoEm: agora,
          atualizadoEm: agora,
          userId: 'user-456',
        );

        final plantaoComNovoLocal = plantaoTeste.copyWith(local: novoLocal);

        expect(plantaoComNovoLocal.local.id, 'local-999');
        expect(plantaoComNovoLocal.local.apelido, 'HC');
      });

      test('deve permitir alterar duração', () {
        final plantao24h = plantaoTeste.copyWith(
          duracao: Duracao.vinteQuatroHoras,
          valor: 2400.0,
        );

        expect(plantao24h.duracao, Duracao.vinteQuatroHoras);
        expect(plantao24h.valor, 2400.0);
      });

      test('deve permitir atualizar timestamp', () {
        final novoTimestamp = agora.add(const Duration(hours: 1));
        final plantaoAtualizado = plantaoTeste.copyWith(
          atualizadoEm: novoTimestamp,
        );

        expect(plantaoAtualizado.atualizadoEm, novoTimestamp);
        expect(plantaoAtualizado.criadoEm, agora);
      });
    });

    group('Validação de Campos', () {
      test('deve aceitar valores monetários diversos', () {
        final valores = [800.0, 1200.0, 1500.0, 2400.0, 3000.0];

        for (final valor in valores) {
          final plantao = plantaoTeste.copyWith(valor: valor);
          expect(plantao.valor, valor);
        }
      });

      test('deve aceitar valores decimais', () {
        final plantaoDecimal = plantaoTeste.copyWith(valor: 1234.56);
        expect(plantaoDecimal.valor, 1234.56);
      });

      test('deve aceitar datas de pagamento futuras', () {
        final hoje = DateTime.now();
        final datasFuturas = [
          hoje.add(const Duration(days: 15)),
          hoje.add(const Duration(days: 30)),
          hoje.add(const Duration(days: 45)),
          hoje.add(const Duration(days: 60)),
        ];

        for (final data in datasFuturas) {
          final plantao = plantaoTeste.copyWith(previsaoPagamento: data);
          expect(plantao.previsaoPagamento.isAfter(hoje), true);
        }
      });

      test('deve aceitar datas de pagamento passadas', () {
        final hoje = DateTime.now();
        final dataPast = hoje.subtract(const Duration(days: 30));

        final plantao = plantaoTeste.copyWith(previsaoPagamento: dataPast);
        expect(plantao.previsaoPagamento.isBefore(hoje), true);
      });

      test('deve aceitar diferentes userIds', () {
        final plantaoUsuario1 = plantaoTeste.copyWith(userId: 'user-111');
        final plantaoUsuario2 = plantaoTeste.copyWith(userId: 'user-222');

        expect(plantaoUsuario1.userId, 'user-111');
        expect(plantaoUsuario2.userId, 'user-222');
      });

      test('deve permitir timestamps diferentes para criação e atualização', () {
        final criacao = DateTime(2025, 1, 1);
        final atualizacao = DateTime(2025, 11, 8);

        final plantao = Plantao(
          id: 'plantao-123',
          local: localTeste,
          dataHora: agora,
          duracao: Duracao.dozeHoras,
          valor: 1200.0,
          previsaoPagamento: agora.add(const Duration(days: 30)),
          criadoEm: criacao,
          atualizadoEm: atualizacao,
          userId: 'user-456',
        );

        expect(plantao.criadoEm.isBefore(plantao.atualizadoEm), true);
      });
    });

    group('Cenários de Uso Real', () {
      test('deve criar plantão de 12h não pago', () {
        final plantao = Plantao(
          id: 'plantao-001',
          local: localTeste,
          dataHora: DateTime(2025, 11, 10, 8, 0),
          duracao: Duracao.dozeHoras,
          valor: 1200.0,
          previsaoPagamento: DateTime(2025, 12, 10),
          criadoEm: agora,
          atualizadoEm: agora,
          userId: 'user-456',
        );

        expect(plantao.duracao, Duracao.dozeHoras);
        expect(plantao.pago, false);
        expect(plantao.valor, 1200.0);
      });

      test('deve criar plantão de 24h já pago', () {
        final plantao = Plantao(
          id: 'plantao-002',
          local: localTeste,
          dataHora: DateTime(2025, 10, 15, 8, 0),
          duracao: Duracao.vinteQuatroHoras,
          valor: 2400.0,
          previsaoPagamento: DateTime(2025, 11, 15),
          criadoEm: agora.subtract(const Duration(days: 30)),
          atualizadoEm: agora,
          userId: 'user-456',
          pago: true,
        );

        expect(plantao.duracao, Duracao.vinteQuatroHoras);
        expect(plantao.pago, true);
        expect(plantao.valor, 2400.0);
      });

      test('deve simular fluxo de marcação como pago', () {
        // Plantão criado como não pago
        expect(plantaoTeste.pago, false);

        // Marcar como pago após receber
        final plantaoPago = plantaoTeste.copyWith(
          pago: true,
          atualizadoEm: agora.add(const Duration(days: 30)),
        );

        expect(plantaoPago.pago, true);
        expect(plantaoPago.atualizadoEm.isAfter(plantaoTeste.atualizadoEm), true);
      });

      test('deve simular soft delete de plantão', () {
        expect(plantaoTeste.ativo, true);

        final plantaoDeletado = plantaoTeste.copyWith(
          ativo: false,
          atualizadoEm: agora.add(const Duration(minutes: 1)),
        );

        expect(plantaoDeletado.ativo, false);
        expect(plantaoDeletado.id, plantaoTeste.id);
      });
    });
  });
}

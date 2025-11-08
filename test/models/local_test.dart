import 'package:fizplantao/models/local.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Local Model', () {
    late DateTime agora;
    late Local localTeste;

    setUp(() {
      agora = DateTime.now();
      localTeste = Local(
        id: 'local-123',
        apelido: 'HSL',
        nome: 'Hospital São Lucas',
        criadoEm: agora,
        atualizadoEm: agora,
        ativo: true,
        userId: 'user-456',
      );
    });

    group('Construtor', () {
      test('deve criar Local com todos os campos obrigatórios', () {
        expect(localTeste.id, 'local-123');
        expect(localTeste.apelido, 'HSL');
        expect(localTeste.nome, 'Hospital São Lucas');
        expect(localTeste.criadoEm, agora);
        expect(localTeste.atualizadoEm, agora);
        expect(localTeste.ativo, true);
        expect(localTeste.userId, 'user-456');
      });

      test('deve criar Local com ativo = true por padrão', () {
        final local = Local(
          id: 'local-789',
          apelido: 'Clinica',
          nome: 'Clínica Teste',
          criadoEm: agora,
          atualizadoEm: agora,
          userId: 'user-456',
        );

        expect(local.ativo, true);
      });
    });

    group('copyWith', () {
      test('deve criar cópia com campos alterados', () {
        final localAtualizado = localTeste.copyWith(
          apelido: 'Hospital',
          nome: 'Hospital Novo Nome',
        );

        expect(localAtualizado.id, localTeste.id);
        expect(localAtualizado.apelido, 'Hospital');
        expect(localAtualizado.nome, 'Hospital Novo Nome');
        expect(localAtualizado.criadoEm, localTeste.criadoEm);
        expect(localAtualizado.userId, localTeste.userId);
      });

      test('deve manter campos originais quando não especificados', () {
        final localCopia = localTeste.copyWith();

        expect(localCopia.id, localTeste.id);
        expect(localCopia.apelido, localTeste.apelido);
        expect(localCopia.nome, localTeste.nome);
        expect(localCopia.criadoEm, localTeste.criadoEm);
        expect(localCopia.atualizadoEm, localTeste.atualizadoEm);
        expect(localCopia.ativo, localTeste.ativo);
        expect(localCopia.userId, localTeste.userId);
      });

      test('deve permitir alterar ativo para false (soft delete)', () {
        final localInativado = localTeste.copyWith(ativo: false);

        expect(localInativado.ativo, false);
        expect(localInativado.id, localTeste.id);
      });

      test('deve permitir atualizar timestamp', () {
        final novoTimestamp = agora.add(const Duration(hours: 1));
        final localAtualizado = localTeste.copyWith(
          atualizadoEm: novoTimestamp,
        );

        expect(localAtualizado.atualizadoEm, novoTimestamp);
        expect(localAtualizado.criadoEm, agora);
      });
    });

    group('toString', () {
      test('deve retornar o apelido do local', () {
        expect(localTeste.toString(), 'HSL');
      });

      test('deve funcionar mesmo com apelido vazio', () {
        final localSemApelido = Local(
          id: 'local-000',
          apelido: '',
          nome: 'Local Sem Apelido',
          criadoEm: agora,
          atualizadoEm: agora,
          userId: 'user-456',
        );

        expect(localSemApelido.toString(), '');
      });
    });

    group('Validação de Campos', () {
      test('deve aceitar IDs diferentes', () {
        final local1 = Local(
          id: 'uuid-1',
          apelido: 'A',
          nome: 'Local A',
          criadoEm: agora,
          atualizadoEm: agora,
          userId: 'user-1',
        );

        final local2 = Local(
          id: 'uuid-2',
          apelido: 'B',
          nome: 'Local B',
          criadoEm: agora,
          atualizadoEm: agora,
          userId: 'user-1',
        );

        expect(local1.id, isNot(equals(local2.id)));
      });

      test('deve aceitar diferentes userIds', () {
        final localUsuario1 = localTeste.copyWith(userId: 'user-111');
        final localUsuario2 = localTeste.copyWith(userId: 'user-222');

        expect(localUsuario1.userId, 'user-111');
        expect(localUsuario2.userId, 'user-222');
      });

      test('deve permitir timestamps diferentes para criação e atualização', () {
        final criacao = DateTime(2025, 1, 1);
        final atualizacao = DateTime(2025, 11, 8);

        final local = Local(
          id: 'local-123',
          apelido: 'Teste',
          nome: 'Local Teste',
          criadoEm: criacao,
          atualizadoEm: atualizacao,
          userId: 'user-456',
        );

        expect(local.criadoEm.isBefore(local.atualizadoEm), true);
      });
    });
  });
}

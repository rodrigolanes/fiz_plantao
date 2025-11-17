import 'package:fizplantao/models/local.dart';
import 'package:fizplantao/models/plantao.dart';
import 'package:fizplantao/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart';

import '../helpers/mock_generators.mocks.dart';
import '../mocks/mock_interfaces.dart';

void main() {
  late MockISyncService mockSyncService;
  late MockIAuthService mockAuthService;
  late MockICalendarService mockCalendarService;
  late MockBox<Local> mockLocaisBox;
  late MockBox<Plantao> mockPlantoesBox;
  late DatabaseService databaseService;

  setUp(() {
    mockSyncService = MockISyncService();
    mockAuthService = MockIAuthService();
    mockCalendarService = MockICalendarService();
    mockLocaisBox = MockBox<Local>();
    mockPlantoesBox = MockBox<Plantao>();

    databaseService = DatabaseService(
      syncService: mockSyncService,
      authService: mockAuthService,
      calendarService: mockCalendarService,
      locaisBox: mockLocaisBox,
      plantoesBox: mockPlantoesBox,
      uuid: const Uuid(),
    );

    // Configuração padrão: syncAll sempre completa com sucesso
    when(mockSyncService.syncAll()).thenAnswer((_) async => Future.value());
  });

  group('Local operations', () {
    test('saveLocal deve chamar syncAll após salvar', () async {
      // Arrange
      when(mockAuthService.userId).thenReturn('user123');
      when(mockLocaisBox.put(any, any)).thenAnswer((_) async => Future.value());

      final local = Local(
        id: 'local1',
        apelido: 'HSL',
        nome: 'Hospital A',
        userId: 'user123',
        ativo: true,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );

      // Act
      await databaseService.saveLocal(local);

      // Assert
      verify(mockLocaisBox.put(any, any)).called(1);
      verify(mockSyncService.syncAll()).called(1);
    });

    test('deleteLocal deve marcar como inativo e chamar syncAll', () async {
      // Arrange
      final local = Local(
        id: 'local1',
        apelido: 'HSL',
        nome: 'Hospital A',
        userId: 'user123',
        ativo: true,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );

      when(mockLocaisBox.get('local1')).thenReturn(local);
      when(mockLocaisBox.put(any, any)).thenAnswer((_) async => Future.value());

      // Act
      await databaseService.deleteLocal('local1');

      // Assert
      verify(mockLocaisBox.put(
        'local1',
        argThat(predicate<Local>((l) => l.ativo == false)),
      )).called(1);
      verify(mockSyncService.syncAll()).called(1);
    });

    test('getLocaisAtivos deve filtrar por userId e ativo', () {
      // Arrange
      final locais = [
        Local(
          id: 'local1',
          apelido: 'HSL A',
          nome: 'Hospital A',
          userId: 'user123',
          ativo: true,
          criadoEm: DateTime.now(),
          atualizadoEm: DateTime.now(),
        ),
        Local(
          id: 'local2',
          apelido: 'HSL B',
          nome: 'Hospital B',
          userId: 'user123',
          ativo: false,
          criadoEm: DateTime.now(),
          atualizadoEm: DateTime.now(),
        ),
        Local(
          id: 'local3',
          apelido: 'HSL C',
          nome: 'Hospital C',
          userId: 'user456',
          ativo: true,
          criadoEm: DateTime.now(),
          atualizadoEm: DateTime.now(),
        ),
      ];

      when(mockAuthService.userId).thenReturn('user123');
      when(mockLocaisBox.values).thenReturn(locais);

      // Act
      final result = databaseService.getLocaisAtivos();

      // Assert
      expect(result.length, 1);
      expect(result.first.id, 'local1');
    });

    test('getLocaisAtivos deve retornar lista vazia quando userId é null', () {
      // Arrange
      when(mockAuthService.userId).thenReturn(null);

      // Act
      final result = databaseService.getLocaisAtivos();

      // Assert
      expect(result, isEmpty);
      verifyNever(mockLocaisBox.values);
    });

    test('getAllLocais deve retornar todos os locais do usuário', () {
      // Arrange
      final locais = <Local>[
        Local(
          id: 'local1',
          apelido: 'HSL A',
          nome: 'Hospital A',
          userId: 'user123',
          ativo: true,
          criadoEm: DateTime.now(),
          atualizadoEm: DateTime.now(),
        ),
        Local(
          id: 'local2',
          apelido: 'HSL B',
          nome: 'Hospital B',
          userId: 'user123',
          ativo: false, // Incluir inativos também
          criadoEm: DateTime.now(),
          atualizadoEm: DateTime.now(),
        ),
      ];

      when(mockAuthService.userId).thenReturn('user123');
      when(mockLocaisBox.values).thenReturn(locais);

      // Act
      final result = databaseService.getAllLocais();

      // Assert
      expect(result.length, 2); // Deve incluir ativos E inativos
      expect(result.where((l) => l.ativo).length, 1);
      expect(result.where((l) => !l.ativo).length, 1);
    });
  });

  group('UUID generation', () {
    test('saveLocal deve gerar UUID quando ID não for válido', () async {
      // Arrange
      when(mockAuthService.userId).thenReturn('user123');
      when(mockLocaisBox.put(any, any)).thenAnswer((_) async => Future.value());

      final local = Local(
        id: 'invalid-id',
        apelido: 'HSL',
        nome: 'Hospital A',
        userId: 'user123',
        ativo: true,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );

      // Act
      await databaseService.saveLocal(local);

      // Assert
      final captured = verify(mockLocaisBox.put(captureAny, captureAny)).captured;
      final savedId = captured[0] as String;
      final savedLocal = captured[1] as Local;

      expect(savedId, isNot('invalid-id'));
      expect(savedLocal.id, isNot('invalid-id'));
      // Verifica se é um UUID válido
      expect(
        RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(savedId),
        isTrue,
      );
      verify(mockSyncService.syncAll()).called(1);
    });

    test('saveLocal deve manter UUID quando ID já for válido', () async {
      // Arrange
      const validUuid = '550e8400-e29b-41d4-a716-446655440000';
      when(mockAuthService.userId).thenReturn('user123');
      when(mockLocaisBox.put(any, any)).thenAnswer((_) async => Future.value());

      final local = Local(
        id: validUuid,
        apelido: 'HSL',
        nome: 'Hospital A',
        userId: 'user123',
        ativo: true,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );

      // Act
      await databaseService.saveLocal(local);

      // Assert
      verify(mockLocaisBox.put(validUuid, any)).called(1);
      verify(mockSyncService.syncAll()).called(1);
    });

    test('deletePlantao deve remover evento do calendar quando calendarEventId existe', () async {
      // Arrange
      const calendarEventId = 'calendar-event-123';
      final plantao = Plantao(
        id: 'plantao1',
        local: Local(
          id: 'local1',
          apelido: 'HSL',
          nome: 'Hospital A',
          userId: 'user123',
          ativo: true,
          criadoEm: DateTime.now(),
          atualizadoEm: DateTime.now(),
        ),
        dataHora: DateTime.now(),
        duracao: Duracao.dozeHoras,
        valor: 1500.0,
        previsaoPagamento: DateTime.now().add(const Duration(days: 30)),
        userId: 'user123',
        ativo: true,
        pago: false,
        calendarEventId: calendarEventId,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );

      when(mockPlantoesBox.get('plantao1')).thenReturn(plantao);
      when(mockPlantoesBox.put(any, any)).thenAnswer((_) async => Future.value());
      when(mockCalendarService.removerEventoPlantao(calendarEventId)).thenAnswer((_) async => Future.value());

      // Act
      await databaseService.deletePlantao('plantao1');

      // Assert
      verify(mockCalendarService.removerEventoPlantao(calendarEventId)).called(1);
      verify(mockPlantoesBox.put(
        'plantao1',
        argThat(predicate<Plantao>((p) => p.ativo == false)),
      )).called(1);
      verify(mockSyncService.syncAll()).called(1);
    });

    test('deletePlantao não deve chamar removerEventoPlantao quando calendarEventId é null', () async {
      // Arrange
      final plantao = Plantao(
        id: 'plantao1',
        local: Local(
          id: 'local1',
          apelido: 'HSL',
          nome: 'Hospital A',
          userId: 'user123',
          ativo: true,
          criadoEm: DateTime.now(),
          atualizadoEm: DateTime.now(),
        ),
        dataHora: DateTime.now(),
        duracao: Duracao.dozeHoras,
        valor: 1500.0,
        previsaoPagamento: DateTime.now().add(const Duration(days: 30)),
        userId: 'user123',
        ativo: true,
        pago: false,
        calendarEventId: null, // SEM calendar event ID
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );

      when(mockPlantoesBox.get('plantao1')).thenReturn(plantao);
      when(mockPlantoesBox.put(any, any)).thenAnswer((_) async => Future.value());

      // Act
      await databaseService.deletePlantao('plantao1');

      // Assert
      verifyNever(mockCalendarService.removerEventoPlantao(any));
      verify(mockPlantoesBox.put(any, any)).called(1);
    });
  });

  group('Plantao operations', () {
    test('savePlantao deve criar evento no calendar e chamar syncAll', () async {
      // Arrange
      when(mockPlantoesBox.put(any, any)).thenAnswer((_) async => Future.value());

      final plantao = Plantao(
        id: 'plantao1',
        local: Local(
          id: 'local1',
          apelido: 'HSL',
          nome: 'Hospital A',
          userId: 'user123',
          ativo: true,
          criadoEm: DateTime.now(),
          atualizadoEm: DateTime.now(),
        ),
        dataHora: DateTime.now(),
        duracao: Duracao.dozeHoras,
        valor: 1500.0,
        previsaoPagamento: DateTime.now().add(const Duration(days: 30)),
        userId: 'user123',
        ativo: true,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );

      // Act
      await databaseService.savePlantao(plantao);

      // Assert
      verify(mockPlantoesBox.put(any, any)).called(1);
      verify(mockSyncService.syncAll()).called(1);
    });

    test('syncAll não deve interromper o fluxo se falhar', () async {
      // Arrange
      when(mockSyncService.syncAll()).thenAnswer((_) async => throw Exception('Network error'));
      when(mockLocaisBox.put(any, any)).thenAnswer((_) async => Future.value());

      final local = Local(
        id: 'local1',
        apelido: 'HSL',
        nome: 'Hospital A',
        userId: 'user123',
        ativo: true,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );

      // Act & Assert - não deve lançar exceção
      await expectLater(
        databaseService.saveLocal(local),
        completes,
      );

      verify(mockLocaisBox.put(any, any)).called(1);
      verify(mockSyncService.syncAll()).called(1);
    });
  });
}

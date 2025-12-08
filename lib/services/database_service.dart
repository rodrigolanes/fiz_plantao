import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/local.dart';
import '../models/plantao.dart';
import 'auth_service.dart';
import 'calendar_service.dart';
import 'sync_service.dart';

// Interface abstrata para permitir mocking
abstract class ISyncService {
  Future<void> syncAll();
}

// Interface abstrata para AuthService
abstract class IAuthService {
  String? get userId;
}

// Interface abstrata para CalendarService
abstract class ICalendarService {
  bool get isGoogleIntegrationEnabled;
  Future<bool> get isSyncEnabled;
  Future<void> setSyncEnabled(bool enabled);
  Future<String?> criarEventoPlantao(Plantao plantao);
  Future<void> criarEventoPagamento({
    required DateTime dataPagamento,
    required double valor,
    required String localNome,
    required String plantaoId,
  });
  Future<void> atualizarStatusPagamento({
    required String plantaoId,
    required bool pago,
  });
  Future<void> removerEventoPlantao(String? calendarEventId);
  Future<bool> requestCalendarPermission();
  Future<void> disconnect();
  Future<void> removerTodosEventos();
}

// Implementações concretas que delegam para os services originais
class SyncServiceImpl implements ISyncService {
  final SyncService _service;

  SyncServiceImpl([SyncService? service]) : _service = service ?? SyncService.instance;

  @override
  Future<void> syncAll() => _service.syncAll();
}

class AuthServiceImpl implements IAuthService {
  final AuthService _service;

  AuthServiceImpl([AuthService? service]) : _service = service ?? AuthService.instance;

  @override
  String? get userId => _service.currentUserId;
}

class CalendarServiceImpl implements ICalendarService {
  final CalendarService _service;

  CalendarServiceImpl([CalendarService? service]) : _service = service ?? CalendarService.instance;

  @override
  bool get isGoogleIntegrationEnabled => _service.isGoogleIntegrationEnabled;

  @override
  Future<bool> get isSyncEnabled => _service.isSyncEnabled;

  @override
  Future<void> setSyncEnabled(bool enabled) => _service.setSyncEnabled(enabled);

  @override
  Future<String?> criarEventoPlantao(Plantao plantao) => _service.criarEventoPlantao(plantao);

  @override
  Future<void> criarEventoPagamento({
    required DateTime dataPagamento,
    required double valor,
    required String localNome,
    required String plantaoId,
  }) =>
      _service.criarEventoPagamento(
        dataPagamento: dataPagamento,
        valor: valor,
        localNome: localNome,
        plantaoId: plantaoId,
      );

  @override
  Future<void> atualizarStatusPagamento({
    required String plantaoId,
    required bool pago,
  }) =>
      _service.atualizarStatusPagamento(
        plantaoId: plantaoId,
        pago: pago,
      );

  @override
  Future<void> removerEventoPlantao(String? calendarEventId) => _service.removerEventoPlantao(calendarEventId);

  @override
  Future<bool> requestCalendarPermission() => _service.requestCalendarPermission();

  @override
  Future<void> disconnect() => _service.disconnect();

  @override
  Future<void> removerTodosEventos() => _service.removerTodosEventos();
}

class DatabaseService {
  final ISyncService _syncService;
  final IAuthService _authService;
  final ICalendarService _calendarService;
  final Uuid _uuid;
  final Box<Local> _locaisBox;
  final Box<Plantao> _plantoesBox;

  // Getters públicos para os boxes (necessários para SyncService)
  Box<Local> get locaisBox => _locaisBox;
  Box<Plantao> get plantoesBox => _plantoesBox;

  // Construtor com dependências injetáveis
  DatabaseService({
    ISyncService? syncService,
    IAuthService? authService,
    ICalendarService? calendarService,
    Uuid? uuid,
    Box<Local>? locaisBox,
    Box<Plantao>? plantoesBox,
  })  : _syncService = syncService ?? SyncServiceImpl(),
        _authService = authService ?? AuthServiceImpl(),
        _calendarService = calendarService ?? CalendarServiceImpl(),
        _uuid = uuid ?? const Uuid(),
        _locaisBox = locaisBox ?? Hive.box<Local>('locais'),
        _plantoesBox = plantoesBox ?? Hive.box<Plantao>('plantoes');

  // Instância singleton para uso em produção
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService();

  // Método para substituir a instância (útil em testes)
  static void setInstance(DatabaseService service) {
    _instance = service;
  }

  // Local operations
  List<Local> getAllLocais() {
    final userId = _authService.userId;
    if (userId == null) return [];
    return _locaisBox.values.where((l) => l.userId == userId).toList();
  }

  List<Local> getLocaisAtivos() {
    final userId = _authService.userId;
    if (userId == null) return [];
    return _locaisBox.values.where((l) => l.ativo && l.userId == userId).toList();
  }

  Future<void> saveLocal(Local local) async {
    final agora = DateTime.now();
    final id = _isUuid(local.id) ? local.id : _uuid.v4();
    final novo = local.copyWith(
      id: id,
      criadoEm: local.criadoEm,
      atualizadoEm: agora,
    );
    await _locaisBox.put(id, novo);

    await _syncService.syncAll().catchError((e) => null);
  }

  bool _isUuid(String value) {
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(value);
  }

  Future<void> updateLocal(Local local) async {
    final agora = DateTime.now();
    final atualizado = local.copyWith(atualizadoEm: agora);
    await _locaisBox.put(atualizado.id, atualizado);

    await _syncService.syncAll().catchError((e) => null);
  }

  Future<void> deleteLocal(String id) async {
    final local = _locaisBox.get(id);
    if (local != null) {
      final agora = DateTime.now();
      final updated = local.copyWith(
        ativo: false,
        deletadoEm: agora,
        atualizadoEm: agora,
      );
      await _locaisBox.put(id, updated);

      await _syncService.syncAll().catchError((e) => null);
    }
  }

  // Plantao operations
  List<Plantao> getAllPlantoes() {
    final userId = _authService.userId;
    if (userId == null) return [];
    return _plantoesBox.values.where((p) => p.userId == userId).toList();
  }

  List<Plantao> getPlantoesAtivos() {
    final userId = _authService.userId;
    if (userId == null) return [];
    return _plantoesBox.values.where((p) => p.ativo && p.userId == userId).toList()
      ..sort((a, b) => a.dataHora.compareTo(b.dataHora));
  }

  Future<void> savePlantao(Plantao plantao) async {
    try {
      final agora = DateTime.now();
      final id = _isUuid(plantao.id) ? plantao.id : _uuid.v4();
      final novo = plantao.copyWith(
        id: id,
        criadoEm: plantao.criadoEm,
        atualizadoEm: agora,
      );

      final calendarEventId = await _calendarService.criarEventoPlantao(novo);

      final plantaoFinal = calendarEventId != null ? novo.copyWith(calendarEventId: calendarEventId) : novo;
      await _plantoesBox.put(id, plantaoFinal);

      await _calendarService.criarEventoPagamento(
        dataPagamento: plantaoFinal.previsaoPagamento,
        valor: plantaoFinal.valor,
        localNome: plantaoFinal.local.nome,
        plantaoId: plantaoFinal.id,
      );

      await _syncService.syncAll().catchError((e) => null);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Erro ao salvar plantão',
        information: [
          'userId: ${_authService.userId}',
          'localNome: ${plantao.local.nome}',
        ],
      );
      rethrow;
    }
  }

  Future<void> updatePlantao(Plantao plantao) async {
    try {
      final agora = DateTime.now();
      final atualizado = plantao.copyWith(atualizadoEm: agora);

      final calendarEventId = await _calendarService.criarEventoPlantao(atualizado);
      final plantaoFinal = calendarEventId != null ? atualizado.copyWith(calendarEventId: calendarEventId) : atualizado;

      await _plantoesBox.put(plantaoFinal.id, plantaoFinal);

      await _calendarService.criarEventoPagamento(
        dataPagamento: plantaoFinal.previsaoPagamento,
        valor: plantaoFinal.valor,
        localNome: plantaoFinal.local.nome,
        plantaoId: plantaoFinal.id,
      );

      await _syncService.syncAll().catchError((e) => null);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Erro ao atualizar plantão',
        information: [
          'userId: ${_authService.userId}',
          'plantaoId: ${plantao.id}',
        ],
      );
      rethrow;
    }
  }

  Future<void> deletePlantao(String id) async {
    try {
      final plantao = _plantoesBox.get(id);
      if (plantao != null) {
        final calendarEventId = plantao.calendarEventId;
        final agora = DateTime.now();

        final updated = plantao.copyWith(
          ativo: false,
          deletadoEm: agora,
          atualizadoEm: agora,
        );
        await _plantoesBox.put(id, updated);

        // Remover evento do calendário com timeout de 10 segundos
        if (calendarEventId != null) {
          try {
            await _calendarService.removerEventoPlantao(calendarEventId).timeout(const Duration(seconds: 10));
          } catch (e, stack) {
            // Registra erro mas continua (calendar é secundário)
            FirebaseCrashlytics.instance.recordError(
              e,
              stack,
              reason: 'Falha ao remover evento do calendário',
              information: ['calendarEventId: $calendarEventId', 'plantaoId: $id'],
            );
          }
        }

        // Atualizar evento de pagamento com timeout
        try {
          await _calendarService
              .criarEventoPagamento(
                dataPagamento: plantao.previsaoPagamento,
                valor: 0,
                localNome: plantao.local.nome,
                plantaoId: plantao.id,
              )
              .timeout(const Duration(seconds: 10));
        } catch (e, stack) {
          // Registra erro mas continua (calendar é secundário)
          FirebaseCrashlytics.instance.recordError(
            e,
            stack,
            reason: 'Falha ao atualizar evento de pagamento',
            information: ['plantaoId: $id'],
          );
        }

        // Sync com timeout de 15 segundos - CRÍTICO, não ignora erro
        await _syncService.syncAll().timeout(const Duration(seconds: 15));
      }
    } catch (e, stack) {
      // Log do erro no Crashlytics com contexto
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Erro ao deletar plantão ID: $id',
        information: [
          'userId: ${_authService.userId}',
          'plantaoId: $id',
        ],
      );
      rethrow; // Re-lança o erro para o UI tratar
    }
  }

  List<Local> getLocaisParaDropdown() {
    return getLocaisAtivos();
  }

  /// Força sincronização completa:
  /// 1. Se Google Calendar ativo: limpa e recria todos os eventos
  /// 2. Sincroniza Hive <-> Supabase
  /// Retorna mapa com resultado de cada etapa
  Future<Map<String, dynamic>> forceSync() async {
    final resultado = <String, dynamic>{
      'calendarSuccess': true,
      'calendarError': null,
      'syncSuccess': false,
      'syncError': null,
    };

    // 1. Calendar sync (se habilitado)
    if (_calendarService.isGoogleIntegrationEnabled) {
      final syncEnabled = await _calendarService.isSyncEnabled;
      if (syncEnabled) {
        try {
          // Remover todos os eventos existentes
          await _calendarService.removerTodosEventos().timeout(const Duration(seconds: 30));

          // Recriar eventos de todos os plantões ativos
          final plantoesAtivos = getPlantoesAtivos();
          for (final plantao in plantoesAtivos) {
            try {
              final calendarEventId =
                  await _calendarService.criarEventoPlantao(plantao).timeout(const Duration(seconds: 10));

              // Atualizar plantão com novo calendarEventId se necessário
              if (calendarEventId != null && plantao.calendarEventId != calendarEventId) {
                final atualizado = plantao.copyWith(
                  calendarEventId: calendarEventId,
                  atualizadoEm: DateTime.now(),
                );
                await _plantoesBox.put(plantao.id, atualizado);
              }

              // Criar evento de pagamento
              await _calendarService
                  .criarEventoPagamento(
                    dataPagamento: plantao.previsaoPagamento,
                    valor: plantao.valor,
                    localNome: plantao.local.nome,
                    plantaoId: plantao.id,
                  )
                  .timeout(const Duration(seconds: 10));
            } catch (e) {
              // Log erro mas continua com próximo plantão
              FirebaseCrashlytics.instance.recordError(
                e,
                StackTrace.current,
                reason: 'Erro ao recriar evento do plantão durante forceSync',
                information: ['plantaoId: ${plantao.id}'],
              );
            }
          }

          resultado['calendarSuccess'] = true;
        } catch (e, stack) {
          resultado['calendarSuccess'] = false;
          resultado['calendarError'] = e.toString();
          FirebaseCrashlytics.instance.recordError(
            e,
            stack,
            reason: 'Erro durante sincronização do calendário',
          );
        }
      }
    }

    // 2. Sync Hive <-> Supabase
    try {
      await _syncService.syncAll().timeout(const Duration(seconds: 30));
      resultado['syncSuccess'] = true;
    } catch (e, stack) {
      resultado['syncSuccess'] = false;
      resultado['syncError'] = e.toString();
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Erro durante sincronização com Supabase',
      );
    }

    return resultado;
  }
}

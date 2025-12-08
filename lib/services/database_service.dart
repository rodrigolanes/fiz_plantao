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
      final updated = local.copyWith(
        ativo: false,
        atualizadoEm: DateTime.now(),
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

        final updated = plantao.copyWith(
          ativo: false,
          atualizadoEm: DateTime.now(),
        );
        await _plantoesBox.put(id, updated);

        if (calendarEventId != null) {
          await _calendarService.removerEventoPlantao(calendarEventId);
        }

        await _calendarService.criarEventoPagamento(
          dataPagamento: plantao.previsaoPagamento,
          valor: 0,
          localNome: plantao.local.nome,
          plantaoId: plantao.id,
        );

        await _syncService.syncAll().catchError((e) => null);
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
}

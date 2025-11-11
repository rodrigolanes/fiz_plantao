import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/local.dart';
import '../models/plantao.dart';
import 'auth_service.dart';
import 'calendar_service.dart';
import 'sync_service.dart';

class DatabaseService {
  static const _uuid = Uuid();

  static Box<Local> get locaisBox => Hive.box<Local>('locais');
  static Box<Plantao> get plantoesBox => Hive.box<Plantao>('plantoes');

  // Local operations
  static List<Local> getAllLocais() {
    final userId = AuthService.userId;
    if (userId == null) return [];
    return locaisBox.values.where((l) => l.userId == userId).toList();
  }

  static List<Local> getLocaisAtivos() {
    final userId = AuthService.userId;
    if (userId == null) return [];
    return locaisBox.values.where((l) => l.ativo && l.userId == userId).toList();
  }

  static Future<void> saveLocal(Local local) async {
    final agora = DateTime.now();
    // Gera UUID se o ID atual não for um UUID válido
    final id = _isUuid(local.id) ? local.id : _uuid.v4();
    final novo = local.copyWith(
      id: id,
      criadoEm: local.criadoEm,
      atualizadoEm: agora,
    );
    await locaisBox.put(id, novo);

    // Sincronização automática
    SyncService.syncAll().catchError((e) => null);
  }

  static bool _isUuid(String value) {
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(value);
  }

  static Future<void> updateLocal(Local local) async {
    final agora = DateTime.now();
    final atualizado = local.copyWith(atualizadoEm: agora);
    await locaisBox.put(atualizado.id, atualizado);

    // Sincronização automática
    SyncService.syncAll().catchError((e) => null);
  }

  static Future<void> deleteLocal(String id) async {
    final local = locaisBox.get(id);
    if (local != null) {
      final updated = local.copyWith(
        ativo: false,
        atualizadoEm: DateTime.now(),
      );
      await locaisBox.put(id, updated);

      // Sincronização automática
      SyncService.syncAll().catchError((e) => null);
    }
  }

  // Plantao operations
  static List<Plantao> getAllPlantoes() {
    final userId = AuthService.userId;
    if (userId == null) return [];
    return plantoesBox.values.where((p) => p.userId == userId).toList();
  }

  static List<Plantao> getPlantoesAtivos() {
    final userId = AuthService.userId;
    if (userId == null) return [];
    return plantoesBox.values.where((p) => p.ativo && p.userId == userId).toList()
      ..sort((a, b) => a.dataHora.compareTo(b.dataHora));
  }

  static Future<void> savePlantao(Plantao plantao) async {
    final agora = DateTime.now();
    // Gera UUID se o ID atual não for um UUID válido
    final id = _isUuid(plantao.id) ? plantao.id : _uuid.v4();
    final novo = plantao.copyWith(
      id: id,
      criadoEm: plantao.criadoEm,
      atualizadoEm: agora,
    );
    await plantoesBox.put(id, novo);

    // Sincronizar com Google Calendar se habilitado e salvar ID do evento
    final calendarEventId = await CalendarService.criarEventoPlantao(novo);
    if (calendarEventId != null) {
      final comEventId = novo.copyWith(calendarEventId: calendarEventId);
      await plantoesBox.put(id, comEventId);
    }

    await CalendarService.criarEventoPagamento(
      dataPagamento: novo.previsaoPagamento,
      valor: novo.valor,
      localNome: novo.local.nome,
      plantaoId: novo.id,
    );

    // Sincronização automática
    SyncService.syncAll().catchError((e) => null);
  }

  static Future<void> updatePlantao(Plantao plantao) async {
    final agora = DateTime.now();
    final atualizado = plantao.copyWith(atualizadoEm: agora);

    // Sincronizar com Google Calendar se habilitado e atualizar ID do evento
    final calendarEventId = await CalendarService.criarEventoPlantao(atualizado);
    final comEventId = calendarEventId != null ? atualizado.copyWith(calendarEventId: calendarEventId) : atualizado;

    await plantoesBox.put(comEventId.id, comEventId);

    // Atualizar evento de pagamento
    await CalendarService.criarEventoPagamento(
      dataPagamento: comEventId.previsaoPagamento,
      valor: comEventId.valor,
      localNome: comEventId.local.nome,
      plantaoId: comEventId.id,
    );

    // Sincronização automática
    SyncService.syncAll().catchError((e) => null);
  }

  static Future<void> deletePlantao(String id) async {
    final plantao = plantoesBox.get(id);
    if (plantao != null) {
      // Guardar ID do evento antes de marcar como inativo
      final calendarEventId = plantao.calendarEventId;

      final updated = plantao.copyWith(
        ativo: false,
        atualizadoEm: DateTime.now(),
      );
      await plantoesBox.put(id, updated);

      // Remover evento do plantão do Google Calendar
      if (calendarEventId != null) {
        await CalendarService.removerEventoPlantao(calendarEventId);
      }

      // Atualizar evento de pagamento (remove este plantão da lista)
      await CalendarService.criarEventoPagamento(
        dataPagamento: plantao.previsaoPagamento,
        valor: 0, // Será recalculado na função
        localNome: plantao.local.nome,
        plantaoId: plantao.id,
      );

      // Sincronização automática
      SyncService.syncAll().catchError((e) => null);
    }
  }

  // Retorna todos os locais (ativos e inativos) para exibição em plantões existentes
  static List<Local> getLocaisParaDropdown() {
    // Retorna locais ativos para novos cadastros, mas mantém todos disponíveis
    // para que plantões antigos possam exibir locais desativados
    return getLocaisAtivos();
  }
}

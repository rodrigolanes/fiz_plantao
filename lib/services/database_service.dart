import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/local.dart';
import '../models/plantao.dart';
import 'auth_service.dart';
import 'calendar_service.dart';

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
  }
  
  static bool _isUuid(String value) {
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(value);
  }

  static Future<void> updateLocal(Local local) async {
    final agora = DateTime.now();
    final atualizado = local.copyWith(atualizadoEm: agora);
    await locaisBox.put(atualizado.id, atualizado);
  }

  static Future<void> deleteLocal(String id) async {
    final local = locaisBox.get(id);
    if (local != null) {
      final updated = local.copyWith(
        ativo: false,
        atualizadoEm: DateTime.now(),
      );
      await locaisBox.put(id, updated);
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
    
    // Sincronizar com Google Calendar se habilitado
    await CalendarService.criarEventoPlantao(novo);
    await CalendarService.criarEventoPagamento(
      dataPagamento: novo.previsaoPagamento,
      valor: novo.valor,
      localNome: novo.local.nome,
      plantaoId: novo.id,
    );
  }

  static Future<void> updatePlantao(Plantao plantao) async {
    final agora = DateTime.now();
    final atualizado = plantao.copyWith(atualizadoEm: agora);
    await plantoesBox.put(atualizado.id, atualizado);
    
    // Atualizar status de pagamento no Google Calendar se mudou
    final anterior = plantoesBox.get(plantao.id);
    if (anterior != null && anterior.pago != plantao.pago) {
      await CalendarService.atualizarStatusPagamento(
        plantaoId: plantao.id,
        pago: plantao.pago,
      );
    }
  }

  static Future<void> deletePlantao(String id) async {
    final plantao = plantoesBox.get(id);
    if (plantao != null) {
      final updated = plantao.copyWith(
        ativo: false,
        atualizadoEm: DateTime.now(),
      );
      await plantoesBox.put(id, updated);
      
      // Remover eventos do Google Calendar
      await CalendarService.removerEventosPlantao(id);
    }
  }

  // Retorna todos os locais (ativos e inativos) para exibição em plantões existentes
  static List<Local> getLocaisParaDropdown() {
    // Retorna locais ativos para novos cadastros, mas mantém todos disponíveis
    // para que plantões antigos possam exibir locais desativados
    return getLocaisAtivos();
  }
}

import 'package:hive/hive.dart';
import '../models/local.dart';
import '../models/plantao.dart';

class DatabaseService {
  static Box<Local> get locaisBox => Hive.box<Local>('locais');
  static Box<Plantao> get plantoesBox => Hive.box<Plantao>('plantoes');

  // Local operations
  static List<Local> getAllLocais() {
    return locaisBox.values.toList();
  }

  static List<Local> getLocaisAtivos() {
    return locaisBox.values.where((l) => l.ativo).toList();
  }

  static Future<void> saveLocal(Local local) async {
    // Usa o ID como chave para facilitar updates
    await locaisBox.put(local.id, local);
  }

  static Future<void> updateLocal(Local local) async {
    await locaisBox.put(local.id, local);
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
    return plantoesBox.values.toList();
  }

  static List<Plantao> getPlantoesAtivos() {
    return plantoesBox.values
        .where((p) => p.ativo)
        .toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
  }

  static Future<void> savePlantao(Plantao plantao) async {
    await plantoesBox.put(plantao.id, plantao);
  }

  static Future<void> updatePlantao(Plantao plantao) async {
    await plantoesBox.put(plantao.id, plantao);
  }

  static Future<void> deletePlantao(String id) async {
    final plantao = plantoesBox.get(id);
    if (plantao != null) {
      final updated = plantao.copyWith(
        ativo: false,
        atualizadoEm: DateTime.now(),
      );
      await plantoesBox.put(id, updated);
    }
  }

  // Retorna todos os locais (ativos e inativos) para exibição em plantões existentes
  static List<Local> getLocaisParaDropdown() {
    // Retorna locais ativos para novos cadastros, mas mantém todos disponíveis
    // para que plantões antigos possam exibir locais desativados
    return getLocaisAtivos();
  }
}

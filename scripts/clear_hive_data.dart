import 'package:hive_flutter/hive_flutter.dart';

/// Script para limpar dados locais do Hive
/// Use após migração Firebase → Supabase para forçar re-sincronização
///
/// Como usar:
/// 1. Fazer logout no app
/// 2. Executar este script OU deletar boxes manualmente:
///    - Fechar o app
///    - Deletar arquivos em: AppData/Local/fizplantao/
/// 3. Fazer login novamente
/// 4. Sincronizar (dados serão re-criados com UUIDs do Supabase)

void main() async {
  await Hive.initFlutter();

  // Deletar boxes
  await Hive.deleteBoxFromDisk('locais');
  await Hive.deleteBoxFromDisk('plantoes');
  await Hive.deleteBoxFromDisk('config');

  print('✅ Boxes deletadas com sucesso!');
  print('Agora faça login no app e sincronize.');
}

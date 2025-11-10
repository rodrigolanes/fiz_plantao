/// Helper para acessar configurações do Supabase de forma segura
/// Evita erros quando propriedades não existem
class ConfigHelper {
  /// Verificar se integrações com Google estão habilitadas
  /// Retorna false se a propriedade não existir no SupabaseConfig
  static bool get isGoogleIntegrationEnabled {
    try {
      // TODO: Descomentar quando SupabaseConfig.enableGoogleIntegrations existir
      // return SupabaseConfig.enableGoogleIntegrations;
      return false; // Por padrão, desabilitado
    } catch (e) {
      return false;
    }
  }
}

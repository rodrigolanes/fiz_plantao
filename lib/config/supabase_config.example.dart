/// Configuração do Supabase
///
/// IMPORTANTE: Este é um arquivo de exemplo. Crie uma cópia chamada
/// supabase_config.dart e adicione suas credenciais reais.
///
/// Nunca commite o arquivo supabase_config.dart com credenciais reais!
class SupabaseConfig {
  /// URL do projeto Supabase
  /// Encontre em: Project Settings > API > Project URL
  static const String supabaseUrl = 'https://seu-projeto.supabase.co';

  /// Anon/Public Key
  /// Encontre em: Project Settings > API > Project API keys > anon public
  static const String supabaseAnonKey = 'sua-anon-key-aqui';

  /// ========================================
  /// INTEGRAÇÕES COM GOOGLE (OPCIONAL)
  /// ========================================

  /// Habilitar integrações com Google (Sign-In + Calendar)
  /// true = Habilita login com Google e sincronização com Google Calendar
  /// false = Desabilita todas as funcionalidades do Google
  static const bool enableGoogleIntegrations = false;

  /// Google Web Client ID (para Android) - OPCIONAL
  /// Necessário apenas se enableGoogleIntegrations = true
  /// Encontre em: Google Cloud Console > APIs & Services > Credentials
  /// Copie o Client ID do tipo "Web application" (não Android)
  /// Use null se não for configurar Google Sign-In
  static const String googleWebClientId = 'seu-client-id.apps.googleusercontent.com';
}

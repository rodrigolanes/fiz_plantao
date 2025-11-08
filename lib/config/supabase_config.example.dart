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
  
  /// Google Web Client ID (para Android)
  /// Encontre em: Google Cloud Console > APIs & Services > Credentials
  /// Copie o Client ID do tipo "Web application" (não Android)
  static const String googleWebClientId = 'seu-client-id.apps.googleusercontent.com';
}

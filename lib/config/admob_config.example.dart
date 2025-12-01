/// Template de configuração do Google AdMob
///
/// INSTRUÇÕES:
/// 1. Copie este arquivo para admob_config.dart
/// 2. Substitua os IDs de exemplo pelos seus IDs reais do AdMob
/// 3. Obtenha seus IDs em: https://apps.admob.com/
///
/// IMPORTANTE: Não commite admob_config.dart com IDs reais (opcional)
class AdMobConfig {
  // Application ID do AdMob (obtido no console do AdMob)
  // Formato: ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
  static const String androidAppId = 'ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY';

  // Banner Ad Unit ID para tela principal
  // Formato: ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ
  static const String bannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ';

  // Test Ad Unit IDs do Google (não modificar)
  static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testAppId = 'ca-app-pub-3940256099942544~3347511713';
}

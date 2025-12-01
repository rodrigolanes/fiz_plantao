/// Configuração do Google AdMob
///
/// INSTRUÇÕES:
/// 1. Obtenha seus IDs em: https://apps.admob.com/
/// 2. Substitua os IDs de teste pelos IDs reais do seu app
///
/// IMPORTANTE: Este arquivo pode conter IDs de produção
class AdMobConfig {
  // Application ID do AdMob (obtido no console do AdMob)
  // Formato: ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
  static const String androidAppId = 'ca-app-pub-0748346709668865~5472216894';

  // Banner Ad Unit ID para tela principal
  // Formato: ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ
  static const String bannerAdUnitId = 'ca-app-pub-0748346709668865/4905240686';

  // Test Ad Unit IDs do Google (não modificar)
  static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testAppId = 'ca-app-pub-3940256099942544~3347511713';
}

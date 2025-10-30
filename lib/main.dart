import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/cadastro_plantao_screen.dart';
import 'models/local.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Locais de exemplo (posteriormente virão do banco de dados)
    final locaisExemplo = [
      Local(
        id: '1',
        apelido: 'HSL',
        nome: 'Hospital São Lucas',
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      ),
      Local(
        id: '2',
        apelido: 'HGE',
        nome: 'Hospital Geral do Estado',
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      ),
      Local(
        id: '3',
        apelido: 'UPA Centro',
        nome: 'UPA 24h Centro',
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      ),
    ];

    return MaterialApp(
      title: 'Fiz Plantão',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      home: CadastroPlantaoScreen(locais: locaisExemplo),
    );
  }
}

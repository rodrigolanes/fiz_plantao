import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' show CalendarApi;

import 'log_service.dart';

/// Serviço centralizado para Google Sign-In
/// Garante que todos os serviços usem a mesma instância e escopos
class GoogleSignInService {
  static final GoogleSignIn instance = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      CalendarApi.calendarScope, // Acesso ao Google Calendar
    ],
    // Web Client ID é necessário no Android para obter idToken
    // Ignora se não estiver configurado (permite rodar sem Google Sign-In)
    serverClientId: kIsWeb ? null : _getGoogleWebClientId(),
  );

  /// Obtém o Google Web Client ID de forma segura
  /// Retorna null se não estiver configurado
  static String? _getGoogleWebClientId() {
    try {
      // Tenta acessar via noSuchMethod - se não existir, retorna null
      // Comentado para evitar erro de compilação
      // return SupabaseConfig.googleWebClientId;
      return null; // TODO: Descomentar quando googleWebClientId for adicionado ao SupabaseConfig
    } catch (e) {
      // googleWebClientId não existe em SupabaseConfig
      LogService.warning('Google Web Client ID não configurado');
      return null;
    }
  }

  /// Debug: imprimir escopos configurados
  static void printScopes() {
    LogService.auth('=== ESCOPOS CONFIGURADOS ===');
    LogService.auth('CalendarApi.calendarScope = "${CalendarApi.calendarScope}"');
    LogService.auth('Escopos totais: ${instance.scopes}');
    LogService.auth('=============================');
  }
}

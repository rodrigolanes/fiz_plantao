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
    // Web Client ID desabilitado até ser configurado
    // serverClientId: kIsWeb ? null : SupabaseConfig.googleWebClientId,
  );

  /// Debug: imprimir escopos configurados
  static void printScopes() {
    LogService.auth('=== ESCOPOS CONFIGURADOS ===');
    LogService.auth('CalendarApi.calendarScope = "${CalendarApi.calendarScope}"');
    LogService.auth('Escopos totais: ${instance.scopes}');
    LogService.auth('=============================');
  }
}

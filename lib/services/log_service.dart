import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Serviço centralizado de logging
///
/// Usa package logger para formatação consistente e níveis de log.
/// Em produção (release mode), apenas logs de WARNING e ERROR são exibidos.
/// Em debug mode, todos os níveis são exibidos.
///
/// Níveis de log:
/// - TRACE: Informações muito detalhadas de debugging
/// - DEBUG: Informações de debugging gerais
/// - INFO: Informações importantes sobre fluxo da aplicação
/// - WARNING: Situações anormais que não impedem funcionamento
/// - ERROR: Erros que impedem operação específica
/// - FATAL: Erros críticos que podem parar a aplicação
class LogService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // Não mostrar stack trace por padrão
      errorMethodCount: 5, // Mostrar 5 linhas de stack em erros
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kDebugMode ? Level.trace : Level.warning,
  );

  /// Logger simples sem formatação para casos específicos
  static final Logger _simpleLogger = Logger(
    printer: SimplePrinter(colors: true),
    level: kDebugMode ? Level.trace : Level.warning,
  );

  // ==================== TRACE ====================
  /// Log de trace - informações muito detalhadas (apenas debug mode)
  static void trace(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  // ==================== DEBUG ====================
  /// Log de debug - informações de debugging (apenas debug mode)
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  // ==================== INFO ====================
  /// Log de informação - eventos importantes da aplicação
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  // ==================== WARNING ====================
  /// Log de warning - situações anormais mas não críticas
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  // ==================== ERROR ====================
  /// Log de erro - falhas que impedem operação específica
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  // ==================== FATAL ====================
  /// Log de erro fatal - erros críticos da aplicação
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  // ==================== HELPERS ====================
  /// Log simples sem formatação - útil para output de dados
  static void simple(String message) {
    _simpleLogger.i(message);
  }

  /// Log de autenticação
  static void auth(String message, [dynamic error]) {
    if (error != null) {
      _logger.w('🔐 AUTH: $message', error: error);
    } else {
      _logger.i('🔐 AUTH: $message');
    }
  }

  /// Log de sincronização com Supabase
  static void sync(String message, [dynamic error]) {
    if (error != null) {
      _logger.w('🔄 SYNC: $message', error: error);
    } else {
      _logger.d('🔄 SYNC: $message');
    }
  }

  /// Log de operações de banco de dados
  static void database(String message, [dynamic error]) {
    if (error != null) {
      _logger.e('💾 DB: $message', error: error);
    } else {
      _logger.d('💾 DB: $message');
    }
  }

  /// Log de operações do Google Calendar
  static void calendar(String message, [dynamic error]) {
    if (error != null) {
      _logger.w('📅 CALENDAR: $message', error: error);
    } else {
      _logger.d('📅 CALENDAR: $message');
    }
  }

  /// Log de navegação e UI
  static void ui(String message, [dynamic error]) {
    if (error != null) {
      _logger.w('🖥️  UI: $message', error: error);
    } else {
      _logger.d('🖥️  UI: $message');
    }
  }
}

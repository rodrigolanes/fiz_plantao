// Mocks manuais para interfaces dos services
// Estes mocks implementam as interfaces com comportamento controlável via mockito

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fizplantao/models/local.dart';
import 'package:fizplantao/models/plantao.dart';
import 'package:fizplantao/services/auth_service.dart';
import 'package:fizplantao/services/calendar_service.dart';
import 'package:fizplantao/services/database_service.dart';
import 'package:fizplantao/services/sync_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// Auth Service Mocks
// ============================================================================

class MockISupabaseAuth extends Mock implements ISupabaseAuth {
  @override
  User? get currentUser => super.noSuchMethod(
        Invocation.getter(#currentUser),
        returnValue: null,
        returnValueForMissingStub: null,
      );

  @override
  Stream<AuthState> get onAuthStateChange => super.noSuchMethod(
        Invocation.getter(#onAuthStateChange),
        returnValue: const Stream.empty(),
        returnValueForMissingStub: const Stream.empty(),
      );

  @override
  Future<AuthResponse> signInWithPassword({required String email, required String password}) => super.noSuchMethod(
        Invocation.method(#signInWithPassword, [], {#email: email, #password: password}),
        returnValue: Future.value(FakeAuthResponse()),
        returnValueForMissingStub: Future.value(FakeAuthResponse()),
      );

  @override
  Future<AuthResponse> signUp({required String email, required String password, String? emailRedirectTo}) =>
      super.noSuchMethod(
        Invocation.method(#signUp, [], {#email: email, #password: password, #emailRedirectTo: emailRedirectTo}),
        returnValue: Future.value(FakeAuthResponse()),
        returnValueForMissingStub: Future.value(FakeAuthResponse()),
      );

  @override
  Future<void> signOut() => super.noSuchMethod(
        Invocation.method(#signOut, []),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );

  @override
  Future<bool> signInWithOAuth(OAuthProvider provider, {String? redirectTo, Map<String, String>? queryParams}) =>
      super.noSuchMethod(
        Invocation.method(#signInWithOAuth, [provider], {#redirectTo: redirectTo, #queryParams: queryParams}),
        returnValue: Future.value(false),
        returnValueForMissingStub: Future.value(false),
      );

  @override
  Future<AuthResponse> signInWithIdToken(
          {required OAuthProvider provider, required String idToken, String? accessToken}) =>
      super.noSuchMethod(
        Invocation.method(#signInWithIdToken, [], {#provider: provider, #idToken: idToken, #accessToken: accessToken}),
        returnValue: Future.value(FakeAuthResponse()),
        returnValueForMissingStub: Future.value(FakeAuthResponse()),
      );

  @override
  Future<void> refreshSession() => super.noSuchMethod(
        Invocation.method(#refreshSession, []),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );

  @override
  Future<void> resend({required OtpType type, required String email, String? emailRedirectTo}) => super.noSuchMethod(
        Invocation.method(#resend, [], {#type: type, #email: email, #emailRedirectTo: emailRedirectTo}),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );

  @override
  Future<void> resetPasswordForEmail(String email, {String? redirectTo}) => super.noSuchMethod(
        Invocation.method(#resetPasswordForEmail, [email], {#redirectTo: redirectTo}),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );
}

class MockIGoogleSignIn extends Mock implements IGoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signIn() => super.noSuchMethod(
        Invocation.method(#signIn, []),
        returnValue: Future<GoogleSignInAccount?>.value(),
        returnValueForMissingStub: Future<GoogleSignInAccount?>.value(),
      );

  @override
  Future<void> signOut() => super.noSuchMethod(
        Invocation.method(#signOut, []),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );
}

class MockIHiveConfig extends Mock implements IHiveConfig {
  final Map<String, dynamic> _storage = {};

  @override
  Future<void> put(String key, dynamic value) {
    _storage[key] = value;
    return super.noSuchMethod(
      Invocation.method(#put, [key, value]),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    );
  }

  @override
  dynamic get(String key) {
    if (_storage.containsKey(key)) {
      return _storage[key];
    }
    return super.noSuchMethod(
      Invocation.method(#get, [key]),
      returnValue: null,
      returnValueForMissingStub: null,
    );
  }

  @override
  Future<void> clear() {
    _storage.clear();
    return super.noSuchMethod(
      Invocation.method(#clear, []),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    );
  }
}

// ============================================================================
// Sync Service Mocks
// ============================================================================

class MockISupabaseClient extends Mock implements ISupabaseClient {
  @override
  GoTrueClient get auth => super.noSuchMethod(
        Invocation.getter(#auth),
        returnValue: FakeGoTrueClient(),
        returnValueForMissingStub: FakeGoTrueClient(),
      );

  @override
  SupabaseQueryBuilder from(String table) => super.noSuchMethod(
        Invocation.method(#from, [table]),
        returnValue: FakeSupabaseQueryBuilder(),
        returnValueForMissingStub: FakeSupabaseQueryBuilder(),
      );

  @override
  Future<void> upsert(String table, Map<String, dynamic> data) => super.noSuchMethod(
        Invocation.method(#upsert, [table, data]),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );

  @override
  Stream<Map<String, dynamic>> realtimeChannel(String table, String userId) => super.noSuchMethod(
        Invocation.method(#realtimeChannel, [table, userId]),
        returnValue: const Stream.empty(),
        returnValueForMissingStub: const Stream.empty(),
      );
}

class MockIConnectivity extends Mock implements IConnectivity {
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => super.noSuchMethod(
        Invocation.getter(#onConnectivityChanged),
        returnValue: Stream.value([ConnectivityResult.wifi]),
        returnValueForMissingStub: Stream.value([ConnectivityResult.wifi]),
      );

  @override
  Future<List<ConnectivityResult>> checkConnectivity() => super.noSuchMethod(
        Invocation.method(#checkConnectivity, []),
        returnValue: Future.value([ConnectivityResult.wifi]),
        returnValueForMissingStub: Future.value([ConnectivityResult.wifi]),
      );
}

class MockIHiveRepository extends Mock implements IHiveRepository {
  @override
  Box<Local> get locaisBox => super.noSuchMethod(
        Invocation.getter(#locaisBox),
        returnValue: FakeBox<Local>(),
        returnValueForMissingStub: FakeBox<Local>(),
      );

  @override
  Box<Plantao> get plantoesBox => super.noSuchMethod(
        Invocation.getter(#plantoesBox),
        returnValue: FakeBox<Plantao>(),
        returnValueForMissingStub: FakeBox<Plantao>(),
      );

  @override
  Future<void> savePlantao(Plantao plantao) => super.noSuchMethod(
        Invocation.method(#savePlantao, [plantao]),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );
}

// ============================================================================
// Database Service Interface Mocks (para outros tests)
// ============================================================================

class MockISyncService extends Mock implements ISyncService {
  @override
  Future<void> syncAll() => super.noSuchMethod(
        Invocation.method(#syncAll, []),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );
}

class MockIAuthService extends Mock implements IAuthService {
  @override
  String? get userId => super.noSuchMethod(
        Invocation.getter(#userId),
        returnValue: null,
        returnValueForMissingStub: null,
      );
}

class MockICalendarService extends Mock implements ICalendarService {
  @override
  bool get isGoogleIntegrationEnabled => super.noSuchMethod(
        Invocation.getter(#isGoogleIntegrationEnabled),
        returnValue: false,
        returnValueForMissingStub: false,
      );

  @override
  Future<bool> get isSyncEnabled => super.noSuchMethod(
        Invocation.getter(#isSyncEnabled),
        returnValue: Future.value(false),
        returnValueForMissingStub: Future.value(false),
      );

  @override
  Future<void> setSyncEnabled(bool enabled) => super.noSuchMethod(
        Invocation.method(#setSyncEnabled, [enabled]),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );

  @override
  Future<String?> criarEventoPlantao(Plantao plantao) => super.noSuchMethod(
        Invocation.method(#criarEventoPlantao, [plantao]),
        returnValue: Future<String?>.value(),
        returnValueForMissingStub: Future<String?>.value(),
      );

  @override
  Future<void> criarEventoPagamento({
    required DateTime dataPagamento,
    required double valor,
    required String localNome,
    required String plantaoId,
  }) =>
      super.noSuchMethod(
        Invocation.method(#criarEventoPagamento, [], {
          #dataPagamento: dataPagamento,
          #valor: valor,
          #localNome: localNome,
          #plantaoId: plantaoId,
        }),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );

  @override
  Future<void> atualizarStatusPagamento({
    required String plantaoId,
    required bool pago,
  }) =>
      super.noSuchMethod(
        Invocation.method(#atualizarStatusPagamento, [], {
          #plantaoId: plantaoId,
          #pago: pago,
        }),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );

  @override
  Future<void> removerEventoPlantao(String? calendarEventId) => super.noSuchMethod(
        Invocation.method(#removerEventoPlantao, [calendarEventId]),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );

  @override
  Future<bool> requestCalendarPermission() => super.noSuchMethod(
        Invocation.method(#requestCalendarPermission, []),
        returnValue: Future.value(false),
        returnValueForMissingStub: Future.value(false),
      );

  @override
  Future<void> disconnect() => super.noSuchMethod(
        Invocation.method(#disconnect, []),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );
}

// ============================================================================
// Calendar Service Mocks
// ============================================================================

class MockIGoogleCalendarAuth extends Mock implements IGoogleCalendarAuth {
  @override
  Future<bool> isAuthorized() => super.noSuchMethod(
        Invocation.method(#isAuthorized, []),
        returnValue: Future.value(false),
        returnValueForMissingStub: Future.value(false),
      );

  @override
  Future<bool> requestAuthorization() => super.noSuchMethod(
        Invocation.method(#requestAuthorization, []),
        returnValue: Future.value(false),
        returnValueForMissingStub: Future.value(false),
      );

  @override
  Future<void> signOut() => super.noSuchMethod(
        Invocation.method(#signOut, []),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );

  @override
  Future<String?> createEvent({
    required String summary,
    required String description,
    required DateTime start,
    required DateTime end,
    String? location,
  }) =>
      super.noSuchMethod(
        Invocation.method(#createEvent, [], {
          #summary: summary,
          #description: description,
          #start: start,
          #end: end,
          #location: location,
        }),
        returnValue: Future<String?>.value(),
        returnValueForMissingStub: Future<String?>.value(),
      );

  @override
  Future<void> updateEvent({
    required String eventId,
    String? summary,
    String? description,
    DateTime? start,
    DateTime? end,
    String? location,
  }) =>
      super.noSuchMethod(
        Invocation.method(#updateEvent, [], {
          #eventId: eventId,
          #summary: summary,
          #description: description,
          #start: start,
          #end: end,
          #location: location,
        }),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );

  @override
  Future<void> deleteEvent(String eventId) => super.noSuchMethod(
        Invocation.method(#deleteEvent, [eventId]),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );
}

class MockIHiveCalendarCache extends Mock implements IHiveCalendarCache {
  @override
  String? get(String key) => super.noSuchMethod(
        Invocation.method(#get, [key]),
        returnValue: null,
        returnValueForMissingStub: null,
      );

  @override
  Future<void> put(String key, String value) => super.noSuchMethod(
        Invocation.method(#put, [key, value]),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );

  @override
  Future<void> delete(String key) => super.noSuchMethod(
        Invocation.method(#delete, [key]),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );
}

// ============================================================================
// Fake classes para retornos (públicas para uso em testes)
// ============================================================================

class FakeAuthResponse extends Fake implements AuthResponse {
  final User? _user;

  FakeAuthResponse({User? user}) : _user = user ?? FakeUser();

  @override
  User? get user => _user;

  @override
  Session? get session => null;
}

class FakeUser extends Fake implements User {
  final String _userId;
  final String? _email;

  FakeUser({String? userId, String? email})
      : _userId = userId ?? 'fake-user-id-123',
        _email = email ?? 'fake@example.com';

  @override
  String get id => _userId;

  @override
  String? get email => _email;

  @override
  String? get emailConfirmedAt => null;
}

class FakeGoTrueClient extends Fake implements GoTrueClient {
  final User? _user;

  FakeGoTrueClient([this._user]);

  @override
  User? get currentUser => _user;
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return FakePostgrestFilterBuilder();
  }

  @override
  PostgrestFilterBuilder<dynamic> insert(
    dynamic values, {
    bool? defaultToNull,
    String? returning,
  }) {
    return FakePostgrestFilterBuilder();
  }

  @override
  PostgrestFilterBuilder<dynamic> upsert(
    dynamic values, {
    bool? defaultToNull,
    bool? ignoreDuplicates,
    String? onConflict,
    String? returning,
  }) {
    return FakePostgrestFilterBuilder();
  }
}

class FakePostgrestFilterBuilder extends Fake implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> _data;

  FakePostgrestFilterBuilder([this._data = const []]);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> filter(String column, String operator, dynamic value) => this;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) async {
    try {
      final result = await Future.value(_data);
      return onValue(result);
    } catch (e) {
      if (onError != null) {
        return onError(e);
      }
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> call() async => _data;
}

class FakeBox<T> extends Fake implements Box<T> {
  @override
  Iterable<T> get values => [];
}

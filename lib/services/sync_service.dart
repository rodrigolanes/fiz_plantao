import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/local.dart';
import '../models/plantao.dart';
import 'log_service.dart';

// Interface abstrata para SupabaseClient
abstract class ISupabaseClient {
  GoTrueClient get auth;
  SupabaseQueryBuilder from(String table);
}

// Interface abstrata para Connectivity
abstract class IConnectivity {
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
  Future<List<ConnectivityResult>> checkConnectivity();
}

// Interface abstrata para acesso aos Hive boxes
abstract class IHiveRepository {
  Box<Local> get locaisBox;
  Box<Plantao> get plantoesBox;
}

// Implementações concretas que delegam para os clients originais
class SupabaseClientImpl implements ISupabaseClient {
  final SupabaseClient _client;

  SupabaseClientImpl([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  @override
  GoTrueClient get auth => _client.auth;

  @override
  SupabaseQueryBuilder from(String table) => _client.from(table);
}

class ConnectivityImpl implements IConnectivity {
  final Connectivity _connectivity;

  ConnectivityImpl([Connectivity? connectivity]) : _connectivity = connectivity ?? Connectivity();

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _connectivity.onConnectivityChanged;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() => _connectivity.checkConnectivity();
}

class HiveRepositoryImpl implements IHiveRepository {
  @override
  Box<Local> get locaisBox => Hive.box<Local>('locais');

  @override
  Box<Plantao> get plantoesBox => Hive.box<Plantao>('plantoes');
}

/// Serviço de sincronização entre Hive (local) e Supabase (remoto)
/// Estratégia: Last-write-wins baseado em timestamps
class SyncService {
  final ISupabaseClient _supabase;
  final IConnectivity _connectivity;
  final IHiveRepository _hiveRepo;

  // Status de sincronização
  final StreamController<SyncStatus> _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncStatus _currentStatus = SyncStatus.idle;

  // Última sincronização bem-sucedida
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  // Queue de operações pendentes
  final List<PendingOperation> _pendingOperations = [];

  // Flag para saber se já foi inicializado
  bool _initialized = false;

  // Construtor com dependências injetáveis
  SyncService({
    ISupabaseClient? supabase,
    IConnectivity? connectivity,
    IHiveRepository? hiveRepo,
  })  : _supabase = supabase ?? SupabaseClientImpl(),
        _connectivity = connectivity ?? ConnectivityImpl(),
        _hiveRepo = hiveRepo ?? HiveRepositoryImpl();

  // Instância singleton para uso em produção
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService();

  // Método para substituir a instância (útil em testes)
  static void setInstance(SyncService service) {
    _instance = service;
  }

  // NOTA: Getters estáticos removidos para evitar conflito de nomes
  // Use SyncService.instance.statusStream e SyncService.instance.lastSyncTime

  /// Inicializa listeners de sincronização automática
  /// Deve ser chamado após o usuário fazer login
  void initialize() {
    if (_initialized) return; // Já inicializado

    final user = _supabase.auth.currentUser;
    if (user == null) {
      // Não há usuário logado, não inicializa os listeners
      return;
    }

    _initialized = true;

    // Listener de mudanças de conectividade
    _connectivity.onConnectivityChanged.listen((result) {
      if (result.contains(ConnectivityResult.mobile) || result.contains(ConnectivityResult.wifi)) {
        // Conectou - tenta sincronizar operações pendentes
        _processPendingOperations();
      }
    });

    // Listener de mudanças remotas (Locais)
    _supabase.from('locais').stream(primaryKey: ['id']).eq('user_id', user.id).listen(
          _handleRemoteLocaisChange,
          onError: (error, stackTrace) {
            LogService.sync('Erro no Realtime listener de Locais', error);
            // Não rethrow - continua funcionando offline, será sincronizado no próximo sync manual
          },
        );

    // Listener de mudanças remotas (Plantões)
    _supabase.from('plantoes').stream(primaryKey: ['id']).eq('user_id', user.id).listen(
          _handleRemotePlantoesChange,
          onError: (error, stackTrace) {
            LogService.sync('Erro no Realtime listener de Plantões', error);
            // Não rethrow - continua funcionando offline, será sincronizado no próximo sync manual
          },
        );
  }

  // NOTA: Método estático removido para evitar conflito de nomes
  // Use SyncService.instance.initialize()

  /// Retorna o ID do usuário autenticado
  String _getCurrentUserId() {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    return user.id;
  }

  /// Sincronização bidirecional completa
  /// IMPORTANTE: Ordem Download → Upload para evitar sobrescrita de dados mais recentes
  Future<void> syncAll() async {
    if (_currentStatus == SyncStatus.syncing) {
      return; // Já está sincronizando
    }

    try {
      _updateStatus(SyncStatus.syncing);

      // Verifica conectividade
      final connectivityResult = await _connectivity.checkConnectivity();
      if (!connectivityResult.contains(ConnectivityResult.mobile) &&
          !connectivityResult.contains(ConnectivityResult.wifi)) {
        throw Exception('Sem conexão com a internet');
      }

      final userId = _getCurrentUserId();

      // 1. Download PRIMEIRO - traz mudanças remotas e faz merge local usando Last-Write-Wins
      // Isso garante que temos a versão mais recente antes de enviar mudanças locais
      await _downloadRemoteChanges(userId).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('Timeout ao baixar mudanças remotas'),
      );

      // 2. Upload DEPOIS - envia mudanças locais que são mais recentes que o remoto
      // O upload só sobrescreve se local.atualizadoEm > remoto.atualizadoEm
      await _uploadLocalChanges(userId).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('Timeout ao enviar mudanças locais'),
      );

      _lastSyncTime = DateTime.now();
      _updateStatus(SyncStatus.synced);
      LogService.sync('Sincronização completa realizada');
    } on TimeoutException catch (e) {
      LogService.sync('Timeout na sincronização - Realtime pode estar indisponível', e);
      _updateStatus(SyncStatus.error, 'Timeout na sincronização');
      // Não rethrow - app continua funcionando offline
    } catch (e) {
      LogService.sync('Erro na sincronização completa', e);
      _updateStatus(SyncStatus.error, e.toString());
      rethrow;
    }
  }

  // NOTA: Método estático removido para evitar conflito de nomes
  // Use SyncService.instance.syncAll()

  /// Faz upload apenas dos dados locais para o servidor
  Future<void> uploadLocalData() async {
    try {
      _updateStatus(SyncStatus.syncing);
      final userId = _getCurrentUserId();
      await _uploadLocalChanges(userId).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('Timeout ao enviar mudanças locais'),
      );
      _updateStatus(SyncStatus.synced);
      LogService.sync('Upload de dados locais concluído');
    } catch (e) {
      LogService.sync('Erro no upload de dados locais', e);
      _updateStatus(SyncStatus.error, e.toString());
      rethrow;
    }
  }

  /// Faz download apenas dos dados remotos para local
  Future<void> downloadRemoteData() async {
    try {
      _updateStatus(SyncStatus.syncing);
      final userId = _getCurrentUserId();
      await _downloadRemoteChanges(userId).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('Timeout ao baixar mudanças remotas'),
      );
      _updateStatus(SyncStatus.synced);
      LogService.sync('Download de dados remotos concluído');
    } catch (e) {
      LogService.sync('Erro no download de dados remotos', e);
      _updateStatus(SyncStatus.error, e.toString());
      rethrow;
    }
  }

  /// Sincronização com retry automático e backoff exponencial
  /// Útil para recuperação de falhas transitórias (Realtime indisponível, etc)
  Future<void> syncWithRetry({int maxAttempts = 3}) async {
    int attempt = 0;

    while (attempt < maxAttempts) {
      try {
        await syncAll();
        return; // Sucesso
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) {
          LogService.sync('Falha na sincronização após $maxAttempts tentativas', e);
          rethrow; // Falha final
        }

        // Backoff exponencial: 2s, 4s, 8s...
        final delaySeconds = 2 * (1 << (attempt - 1));
        LogService.sync(
            'Sincronização falhou, tentando novamente em ${delaySeconds}s (tentativa $attempt/$maxAttempts)');
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
  }

  /// Upload de mudanças locais para o servidor
  Future<void> _uploadLocalChanges(String userId) async {
    // Upload Locais (inclui inativos para propagar soft delete)
    final locaisLocais = _hiveRepo.locaisBox.values.where((l) => l.userId == userId).toList();

    for (final local in locaisLocais) {
      // Verifica se já existe remotamente
      final remoteLocal = await _supabase.from('locais').select().eq('id', local.id).maybeSingle();

      if (remoteLocal == null) {
        // Não existe remotamente - inserir com ID gerado localmente
        await _supabase.from('locais').insert({
          'id': local.id, // Usa o UUID gerado localmente
          'user_id': userId,
          'apelido': local.apelido,
          'nome': local.nome,
          'criado_em': local.criadoEm.toIso8601String(),
          'atualizado_em': local.atualizadoEm.toIso8601String(),
          'ativo': local.ativo,
          'deletado_em': local.deletadoEm?.toIso8601String(),
        });
      } else {
        // Existe - verificar qual é mais recente
        final remoteUpdatedAt = DateTime.parse(remoteLocal['atualizado_em']);
        if (local.atualizadoEm.isAfter(remoteUpdatedAt)) {
          // Local é mais recente - atualizar remoto
          await _supabase.from('locais').update({
            'apelido': local.apelido,
            'nome': local.nome,
            'atualizado_em': local.atualizadoEm.toIso8601String(),
            'ativo': local.ativo,
            'deletado_em': local.deletadoEm?.toIso8601String(),
          }).eq('id', local.id);
        }
      }
    }

    // Upload Plantões (inclui inativos para propagar soft delete)
    final plantoesLocais = _hiveRepo.plantoesBox.values.where((p) => p.userId == userId).toList();

    for (final plantao in plantoesLocais) {
      final remotePlantao = await _supabase.from('plantoes').select().eq('id', plantao.id).maybeSingle();

      if (remotePlantao == null) {
        // Não existe remotamente - inserir com ID gerado localmente
        await _supabase.from('plantoes').insert({
          'id': plantao.id, // Usa o UUID gerado localmente
          'user_id': userId,
          'local_id': plantao.local.id,
          'data_hora': plantao.dataHora.toIso8601String(),
          'duracao': plantao.duracao.name,
          'valor': plantao.valor,
          'previsao_pagamento': plantao.previsaoPagamento.toIso8601String(),
          'pago': plantao.pago,
          'calendar_event_id': plantao.calendarEventId,
          'calendar_payment_event_id': plantao.calendarPaymentEventId,
          'criado_em': plantao.criadoEm.toIso8601String(),
          'atualizado_em': plantao.atualizadoEm.toIso8601String(),
          'ativo': plantao.ativo,
          'deletado_em': plantao.deletadoEm?.toIso8601String(),
        });
      } else {
        // Existe - verificar qual é mais recente
        final remoteUpdatedAt = DateTime.parse(remotePlantao['atualizado_em']);
        if (plantao.atualizadoEm.isAfter(remoteUpdatedAt)) {
          // Local é mais recente - atualizar remoto
          await _supabase.from('plantoes').update({
            'local_id': plantao.local.id,
            'data_hora': plantao.dataHora.toIso8601String(),
            'duracao': plantao.duracao.name,
            'valor': plantao.valor,
            'previsao_pagamento': plantao.previsaoPagamento.toIso8601String(),
            'pago': plantao.pago,
            'calendar_event_id': plantao.calendarEventId,
            'calendar_payment_event_id': plantao.calendarPaymentEventId,
            'atualizado_em': plantao.atualizadoEm.toIso8601String(),
            'ativo': plantao.ativo,
            'deletado_em': plantao.deletadoEm?.toIso8601String(),
          }).eq('id', plantao.id);
        }
      }
    }
  }

  /// Download de mudanças remotas para local
  Future<void> _downloadRemoteChanges(String userId) async {
    // Download Locais (inclui inativos para manter histórico fiel)
    final remoteLocais = await _supabase.from('locais').select().eq('user_id', userId);

    for (final remoteLocal in remoteLocais) {
      final localId = remoteLocal['id'] as String;
      final localLocal = _hiveRepo.locaisBox.get(localId);
      final remoteUpdatedAt = DateTime.parse(remoteLocal['atualizado_em']);
      final remoteDeletadoEm = remoteLocal['deletado_em'] != null ? DateTime.parse(remoteLocal['deletado_em']) : null;

      if (localLocal == null) {
        // Não existe localmente - criar novo
        final novoLocal = Local(
          id: localId,
          userId: remoteLocal['user_id'],
          apelido: remoteLocal['apelido'],
          nome: remoteLocal['nome'],
          criadoEm: DateTime.parse(remoteLocal['criado_em']),
          atualizadoEm: remoteUpdatedAt,
          ativo: remoteLocal['ativo'] ?? true,
          deletadoEm: remoteDeletadoEm,
        );
        await _hiveRepo.locaisBox.put(localId, novoLocal);
      } else {
        // Existe - merge inteligente com prioridade para deletadoEm
        // Se remoto tem deletadoEm e local não, aplicar delete
        if (remoteDeletadoEm != null && localLocal.deletadoEm == null) {
          // Remoto foi deletado, local ainda não sabia
          if (localLocal.atualizadoEm.isBefore(remoteDeletadoEm)) {
            // Edit local é anterior ao delete remoto, aplicar delete
            final localAtualizado = localLocal.copyWith(
              apelido: remoteLocal['apelido'],
              nome: remoteLocal['nome'],
              atualizadoEm: remoteUpdatedAt,
              ativo: remoteLocal['ativo'] ?? true,
              deletadoEm: remoteDeletadoEm,
            );
            await _hiveRepo.locaisBox.put(localId, localAtualizado);
          } else {
            // Edit local é posterior ao delete - priorizar delete (mais seguro)
            final localAtualizado = localLocal.copyWith(
              atualizadoEm: remoteUpdatedAt,
              ativo: false,
              deletadoEm: remoteDeletadoEm,
            );
            await _hiveRepo.locaisBox.put(localId, localAtualizado);
          }
        } else if (remoteUpdatedAt.isAfter(localLocal.atualizadoEm)) {
          // Remoto é mais recente, atualizar local
          final localAtualizado = localLocal.copyWith(
            apelido: remoteLocal['apelido'],
            nome: remoteLocal['nome'],
            atualizadoEm: remoteUpdatedAt,
            ativo: remoteLocal['ativo'] ?? true,
            deletadoEm: remoteDeletadoEm,
          );
          await _hiveRepo.locaisBox.put(localId, localAtualizado);
        }
      }
    }

    // Download Plantões (inclui inativos)
    final remotePlantoes = await _supabase.from('plantoes').select().eq('user_id', userId);

    for (final remotePlantao in remotePlantoes) {
      final plantaoId = remotePlantao['id'] as String;
      final localPlantao = _hiveRepo.plantoesBox.get(plantaoId);
      final remoteUpdatedAt = DateTime.parse(remotePlantao['atualizado_em']);
      final remoteDeletadoEm =
          remotePlantao['deletado_em'] != null ? DateTime.parse(remotePlantao['deletado_em']) : null;

      // Local associado
      final localDoPlantao = _hiveRepo.locaisBox.get(remotePlantao['local_id']);
      if (localDoPlantao == null) {
        // Se o local não está presente ainda, pulamos este plantão por ora
        continue;
      }

      if (localPlantao == null) {
        // Não existe localmente - criar novo
        final novoPlantao = Plantao(
          id: plantaoId,
          userId: remotePlantao['user_id'],
          local: localDoPlantao,
          dataHora: DateTime.parse(remotePlantao['data_hora']),
          duracao: Duracao.values.firstWhere((d) => d.name == remotePlantao['duracao']),
          valor: (remotePlantao['valor'] as num).toDouble(),
          previsaoPagamento: DateTime.parse(remotePlantao['previsao_pagamento']),
          pago: _getRemoteBooleanField(remotePlantao, 'pago'),
          calendarEventId: remotePlantao['calendar_event_id'],
          calendarPaymentEventId: remotePlantao['calendar_payment_event_id'],
          criadoEm: DateTime.parse(remotePlantao['criado_em']),
          atualizadoEm: remoteUpdatedAt,
          ativo: remotePlantao['ativo'] ?? true,
          deletadoEm: remoteDeletadoEm,
        );
        await _hiveRepo.plantoesBox.put(plantaoId, novoPlantao);
      } else {
        // Existe - merge inteligente com prioridade para deletadoEm
        // Se remoto tem deletadoEm e local não, aplicar delete
        if (remoteDeletadoEm != null && localPlantao.deletadoEm == null) {
          // Remoto foi deletado, local ainda não sabia
          if (localPlantao.atualizadoEm.isBefore(remoteDeletadoEm)) {
            // Edit local é anterior ao delete remoto, aplicar delete
            final plantaoAtualizado = localPlantao.copyWith(
              local: localDoPlantao,
              dataHora: DateTime.parse(remotePlantao['data_hora']),
              duracao: Duracao.values.firstWhere((d) => d.name == remotePlantao['duracao']),
              valor: (remotePlantao['valor'] as num).toDouble(),
              previsaoPagamento: DateTime.parse(remotePlantao['previsao_pagamento']),
              pago: remotePlantao['pago'] ?? false,
              calendarEventId: remotePlantao['calendar_event_id'],
              calendarPaymentEventId: remotePlantao['calendar_payment_event_id'],
              atualizadoEm: remoteUpdatedAt,
              ativo: remotePlantao['ativo'] ?? true,
              deletadoEm: remoteDeletadoEm,
            );
            await _hiveRepo.plantoesBox.put(plantaoId, plantaoAtualizado);
          } else {
            // Edit local é posterior ao delete - priorizar delete (mais seguro)
            final plantaoAtualizado = localPlantao.copyWith(
              atualizadoEm: remoteUpdatedAt,
              ativo: false,
              deletadoEm: remoteDeletadoEm,
            );
            await _hiveRepo.plantoesBox.put(plantaoId, plantaoAtualizado);
          }
        } else if (remoteUpdatedAt.isAfter(localPlantao.atualizadoEm)) {
          // Remoto é mais recente, atualizar local
          final plantaoAtualizado = localPlantao.copyWith(
            local: localDoPlantao,
            dataHora: DateTime.parse(remotePlantao['data_hora']),
            duracao: Duracao.values.firstWhere((d) => d.name == remotePlantao['duracao']),
            valor: (remotePlantao['valor'] as num).toDouble(),
            previsaoPagamento: DateTime.parse(remotePlantao['previsao_pagamento']),
            pago: remotePlantao['pago'] ?? false,
            calendarEventId: remotePlantao['calendar_event_id'],
            calendarPaymentEventId: remotePlantao['calendar_payment_event_id'],
            atualizadoEm: remoteUpdatedAt,
            ativo: remotePlantao['ativo'] ?? true,
            deletadoEm: remoteDeletadoEm,
          );
          await _hiveRepo.plantoesBox.put(plantaoId, plantaoAtualizado);
        }
      }
    }
  }

  /// Processa operações pendentes quando voltar a conectividade
  Future<void> _processPendingOperations() async {
    if (_pendingOperations.isEmpty) return;

    try {
      for (final operation in List.from(_pendingOperations)) {
        await operation.execute();
        _pendingOperations.remove(operation);
      }
    } catch (e) {
      // Falhou - operações continuam na fila
    }
  }

  /// Handler de mudanças remotas em Locais
  void _handleRemoteLocaisChange(List<Map<String, dynamic>> changes) {
    try {
      final box = _hiveRepo.locaisBox;

      for (final data in changes) {
        final id = data['id'] as String;
        final remoteUpdatedAt = DateTime.parse(data['atualizado_em'] as String);
        final remoteDeletadoEm = data['deletado_em'] != null ? DateTime.parse(data['deletado_em'] as String) : null;

        // Buscar local existente no Hive
        final localExistente = box.get(id);

        if (localExistente == null) {
          // Não existe localmente - criar
          final local = Local(
            id: id,
            apelido: data['apelido'] as String,
            nome: data['nome'] as String,
            criadoEm: DateTime.parse(data['criado_em'] as String),
            atualizadoEm: remoteUpdatedAt,
            ativo: data['ativo'] as bool? ?? true,
            userId: data['user_id'] as String,
            deletadoEm: remoteDeletadoEm,
          );
          box.put(id, local);
        } else {
          // Existe - merge com prioridade para deletadoEm
          if (remoteDeletadoEm != null && localExistente.deletadoEm == null) {
            // Remoto foi deletado, local ainda não sabia
            if (localExistente.atualizadoEm.isBefore(remoteDeletadoEm)) {
              // Edit local é anterior ao delete remoto, aplicar delete
              final localAtualizado = localExistente.copyWith(
                apelido: data['apelido'] as String,
                nome: data['nome'] as String,
                atualizadoEm: remoteUpdatedAt,
                ativo: data['ativo'] as bool? ?? true,
                deletadoEm: remoteDeletadoEm,
              );
              box.put(id, localAtualizado);
            } else {
              // Edit local é posterior ao delete - priorizar delete (mais seguro)
              final localAtualizado = localExistente.copyWith(
                atualizadoEm: remoteUpdatedAt,
                ativo: false,
                deletadoEm: remoteDeletadoEm,
              );
              box.put(id, localAtualizado);
            }
          } else if (remoteUpdatedAt.isAfter(localExistente.atualizadoEm)) {
            // Remoto é mais recente, atualizar local
            final localAtualizado = localExistente.copyWith(
              apelido: data['apelido'] as String,
              nome: data['nome'] as String,
              atualizadoEm: remoteUpdatedAt,
              ativo: data['ativo'] as bool? ?? true,
              deletadoEm: remoteDeletadoEm,
            );
            box.put(id, localAtualizado);
          }
        }
      }

      // Atualiza timestamp da última sincronização
      _lastSyncTime = DateTime.now();
    } catch (e) {
      LogService.sync('Erro ao processar mudanças remotas de Locais', e);
    }
  }

  /// Handler de mudanças remotas em Plantões
  void _handleRemotePlantoesChange(List<Map<String, dynamic>> changes) {
    try {
      final plantoesBox = _hiveRepo.plantoesBox;
      final locaisBox = _hiveRepo.locaisBox;

      for (final data in changes) {
        final id = data['id'] as String;
        final remoteUpdatedAt = DateTime.parse(data['atualizado_em'] as String);
        final remoteDeletadoEm = data['deletado_em'] != null ? DateTime.parse(data['deletado_em'] as String) : null;

        // Buscar plantão existente no Hive
        final plantaoExistente = plantoesBox.get(id);

        // Buscar o Local relacionado
        final localId = data['local_id'] as String;
        final local = locaisBox.get(localId);

        if (local == null) {
          LogService.warning('Local $localId não encontrado para Plantão $id - pulando');
          continue; // Pula este plantão se o local não existe
        }

        // Parse da duração
        final duracaoStr = data['duracao'] as String;
        final duracao = duracaoStr == '12h' ? Duracao.dozeHoras : Duracao.vinteQuatroHoras;

        if (plantaoExistente == null) {
          // Não existe localmente - criar
          final plantao = Plantao(
            id: id,
            local: local,
            dataHora: DateTime.parse(data['data_hora'] as String),
            duracao: duracao,
            valor: (data['valor'] as num).toDouble(),
            previsaoPagamento: DateTime.parse(data['previsao_pagamento'] as String),
            pago: _getRemoteBooleanField(data, 'pago'),
            calendarEventId: data['calendar_event_id'] as String?,
            calendarPaymentEventId: data['calendar_payment_event_id'] as String?,
            criadoEm: DateTime.parse(data['criado_em'] as String),
            atualizadoEm: remoteUpdatedAt,
            ativo: data['ativo'] as bool? ?? true,
            userId: data['user_id'] as String,
            deletadoEm: remoteDeletadoEm,
          );
          plantoesBox.put(id, plantao);
        } else {
          // Existe - merge com prioridade para deletadoEm
          if (remoteDeletadoEm != null && plantaoExistente.deletadoEm == null) {
            // Remoto foi deletado, local ainda não sabia
            if (plantaoExistente.atualizadoEm.isBefore(remoteDeletadoEm)) {
              // Edit local é anterior ao delete remoto, aplicar delete
              final plantaoAtualizado = plantaoExistente.copyWith(
                local: local,
                dataHora: DateTime.parse(data['data_hora'] as String),
                duracao: duracao,
                valor: (data['valor'] as num).toDouble(),
                previsaoPagamento: DateTime.parse(data['previsao_pagamento'] as String),
                pago: _getRemoteBooleanField(data, 'pago'),
                calendarEventId: data['calendar_event_id'] as String?,
                calendarPaymentEventId: data['calendar_payment_event_id'] as String?,
                atualizadoEm: remoteUpdatedAt,
                ativo: data['ativo'] as bool? ?? true,
                deletadoEm: remoteDeletadoEm,
              );
              plantoesBox.put(id, plantaoAtualizado);
            } else {
              // Edit local é posterior ao delete - priorizar delete (mais seguro)
              final plantaoAtualizado = plantaoExistente.copyWith(
                atualizadoEm: remoteUpdatedAt,
                ativo: false,
                deletadoEm: remoteDeletadoEm,
              );
              plantoesBox.put(id, plantaoAtualizado);
            }
          } else if (remoteUpdatedAt.isAfter(plantaoExistente.atualizadoEm)) {
            // Remoto é mais recente, atualizar local
            final plantaoAtualizado = plantaoExistente.copyWith(
              local: local,
              dataHora: DateTime.parse(data['data_hora'] as String),
              duracao: duracao,
              valor: (data['valor'] as num).toDouble(),
              previsaoPagamento: DateTime.parse(data['previsao_pagamento'] as String),
              pago: _getRemoteBooleanField(data, 'pago'),
              calendarEventId: data['calendar_event_id'] as String?,
              calendarPaymentEventId: data['calendar_payment_event_id'] as String?,
              atualizadoEm: remoteUpdatedAt,
              ativo: data['ativo'] as bool? ?? true,
              deletadoEm: remoteDeletadoEm,
            );
            plantoesBox.put(id, plantaoAtualizado);
          }
        }
      }

      // Atualiza timestamp da última sincronização
      _lastSyncTime = DateTime.now();
    } catch (e) {
      LogService.sync('Erro ao processar mudanças remotas de Plantões', e);
    }
  }

  /// Atualiza status de sincronização
  void _updateStatus(SyncStatus status, [String? errorMessage]) {
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  /// Adiciona operação à fila de pendentes
  void addPendingOperation(PendingOperation operation) {
    _pendingOperations.add(operation);
  }

  /// Limpa recursos
  void dispose() {
    _statusController.close();
  }

  /// Obtém um valor booleano de um campo remoto, lidando com nulos e diferentes tipos
  static bool _getRemoteBooleanField(Map<String, dynamic> data, String fieldName) {
    final value = data[fieldName];
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }
}

/// Status da sincronização
enum SyncStatus {
  idle,
  syncing,
  synced,
  error,
}

/// Operação pendente para executar quando voltar conectividade
abstract class PendingOperation {
  Future<void> execute();
}

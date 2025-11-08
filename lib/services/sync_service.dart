import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/local.dart';
import '../models/plantao.dart';
import 'database_service.dart';

/// Serviço de sincronização entre Hive (local) e Supabase (remoto)
/// Estratégia: Last-write-wins baseado em timestamps
class SyncService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final Connectivity _connectivity = Connectivity();

  // Status de sincronização
  static final StreamController<SyncStatus> _statusController = StreamController<SyncStatus>.broadcast();
  static Stream<SyncStatus> get statusStream => _statusController.stream;
  static SyncStatus _currentStatus = SyncStatus.idle;

  // Última sincronização bem-sucedida
  static DateTime? _lastSyncTime;
  static DateTime? get lastSyncTime => _lastSyncTime;

  // Queue de operações pendentes
  static final List<PendingOperation> _pendingOperations = [];

  // Flag para saber se já foi inicializado
  static bool _initialized = false;

  /// Inicializa listeners de sincronização automática
  /// Deve ser chamado após o usuário fazer login
  static void initialize() {
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
    _supabase.from('locais').stream(primaryKey: ['id']).eq('user_id', user.id).listen(_handleRemoteLocaisChange);

    // Listener de mudanças remotas (Plantões)
    _supabase.from('plantoes').stream(primaryKey: ['id']).eq('user_id', user.id).listen(_handleRemotePlantoesChange);
  }

  /// Retorna o ID do usuário autenticado
  static String _getCurrentUserId() {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    return user.id;
  }

  /// Sincronização bidirecional completa
  static Future<void> syncAll() async {
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

      // 1. Upload de dados locais modificados
      await _uploadLocalChanges(userId);

      // 2. Download de dados remotos modificados
      await _downloadRemoteChanges(userId);

      _lastSyncTime = DateTime.now();
      _updateStatus(SyncStatus.synced);
    } catch (e) {
      _updateStatus(SyncStatus.error, e.toString());
      rethrow;
    }
  }

  /// Faz upload apenas dos dados locais para o servidor
  static Future<void> uploadLocalData() async {
    try {
      _updateStatus(SyncStatus.syncing);
      final userId = _getCurrentUserId();
      await _uploadLocalChanges(userId);
      _updateStatus(SyncStatus.synced);
    } catch (e) {
      _updateStatus(SyncStatus.error, e.toString());
      rethrow;
    }
  }

  /// Faz download apenas dos dados remotos para local
  static Future<void> downloadRemoteData() async {
    try {
      _updateStatus(SyncStatus.syncing);
      final userId = _getCurrentUserId();
      await _downloadRemoteChanges(userId);
      _updateStatus(SyncStatus.synced);
    } catch (e) {
      _updateStatus(SyncStatus.error, e.toString());
      rethrow;
    }
  }

  /// Upload de mudanças locais para o servidor
  static Future<void> _uploadLocalChanges(String userId) async {
    // Upload Locais (inclui inativos para propagar soft delete)
    final locaisLocais = DatabaseService.getAllLocais().where((l) => l.userId == userId).toList();

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
          }).eq('id', local.id);
        }
      }
    }

    // Upload Plantões (inclui inativos para propagar soft delete)
    final plantoesLocais = DatabaseService.getAllPlantoes().where((p) => p.userId == userId).toList();

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
          'criado_em': plantao.criadoEm.toIso8601String(),
          'atualizado_em': plantao.atualizadoEm.toIso8601String(),
          'ativo': plantao.ativo,
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
            'atualizado_em': plantao.atualizadoEm.toIso8601String(),
            'ativo': plantao.ativo,
          }).eq('id', plantao.id);
        }
      }
    }
  }

  /// Download de mudanças remotas para local
  static Future<void> _downloadRemoteChanges(String userId) async {
    // Download Locais (inclui inativos para manter histórico fiel)
    final remoteLocais = await _supabase.from('locais').select().eq('user_id', userId);

    for (final remoteLocal in remoteLocais) {
      final localId = remoteLocal['id'] as String;
      final localLocal = DatabaseService.locaisBox.get(localId);
      final remoteUpdatedAt = DateTime.parse(remoteLocal['atualizado_em']);

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
        );
        await DatabaseService.locaisBox.put(localId, novoLocal);
      } else if (remoteUpdatedAt.isAfter(localLocal.atualizadoEm)) {
        // Existe mas remoto é mais recente - atualizar
        final localAtualizado = localLocal.copyWith(
          apelido: remoteLocal['apelido'],
          nome: remoteLocal['nome'],
          atualizadoEm: remoteUpdatedAt,
          ativo: remoteLocal['ativo'] ?? true,
        );
        await DatabaseService.locaisBox.put(localId, localAtualizado);
      }
    }

    // Download Plantões (inclui inativos)
    final remotePlantoes = await _supabase.from('plantoes').select().eq('user_id', userId);

    for (final remotePlantao in remotePlantoes) {
      final plantaoId = remotePlantao['id'] as String;
      final localPlantao = DatabaseService.plantoesBox.get(plantaoId);
      final remoteUpdatedAt = DateTime.parse(remotePlantao['atualizado_em']);

      // Local associado
      final localDoPlantao = DatabaseService.locaisBox.get(remotePlantao['local_id']);
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
          criadoEm: DateTime.parse(remotePlantao['criado_em']),
          atualizadoEm: remoteUpdatedAt,
          ativo: remotePlantao['ativo'] ?? true,
        );
        await DatabaseService.plantoesBox.put(plantaoId, novoPlantao);
      } else if (remoteUpdatedAt.isAfter(localPlantao.atualizadoEm)) {
        // Existe mas remoto é mais recente - atualizar
        final plantaoAtualizado = localPlantao.copyWith(
          local: localDoPlantao,
          dataHora: DateTime.parse(remotePlantao['data_hora']),
          duracao: Duracao.values.firstWhere((d) => d.name == remotePlantao['duracao']),
          valor: (remotePlantao['valor'] as num).toDouble(),
          previsaoPagamento: DateTime.parse(remotePlantao['previsao_pagamento']),
          atualizadoEm: remoteUpdatedAt,
          ativo: remotePlantao['ativo'] ?? true,
        );
        await DatabaseService.plantoesBox.put(plantaoId, plantaoAtualizado);
      }
    }
  }

  /// Processa operações pendentes quando voltar a conectividade
  static Future<void> _processPendingOperations() async {
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
  static void _handleRemoteLocaisChange(List<Map<String, dynamic>> changes) {
    try {
      final box = DatabaseService.locaisBox;
      
      for (final data in changes) {
        final id = data['id'] as String;
        final remoteUpdatedAt = DateTime.parse(data['atualizado_em'] as String);
        
        // Buscar local existente no Hive
        final localExistente = box.get(id);
        
        // Se não existe localmente ou remoto é mais recente, atualiza
        if (localExistente == null || remoteUpdatedAt.isAfter(localExistente.atualizadoEm)) {
          final local = Local(
            id: id,
            apelido: data['apelido'] as String,
            nome: data['nome'] as String,
            criadoEm: DateTime.parse(data['criado_em'] as String),
            atualizadoEm: remoteUpdatedAt,
            ativo: data['ativo'] as bool? ?? true,
            userId: data['user_id'] as String,
          );
          
          box.put(id, local);
        }
      }
      
      // Atualiza timestamp da última sincronização
      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('Erro ao processar mudanças remotas de Locais: $e');
    }
  }

  /// Handler de mudanças remotas em Plantões
  static void _handleRemotePlantoesChange(List<Map<String, dynamic>> changes) {
    try {
      final plantoesBox = DatabaseService.plantoesBox;
      final locaisBox = DatabaseService.locaisBox;
      
      for (final data in changes) {
        final id = data['id'] as String;
        final remoteUpdatedAt = DateTime.parse(data['atualizado_em'] as String);
        
        // Buscar plantão existente no Hive
        final plantaoExistente = plantoesBox.get(id);
        
        // Se não existe localmente ou remoto é mais recente, atualiza
        if (plantaoExistente == null || remoteUpdatedAt.isAfter(plantaoExistente.atualizadoEm)) {
          // Buscar o Local relacionado
          final localId = data['local_id'] as String;
          final local = locaisBox.get(localId);
          
          if (local == null) {
            debugPrint('Local $localId não encontrado para Plantão $id');
            continue; // Pula este plantão se o local não existe
          }
          
          // Parse da duração
          final duracaoStr = data['duracao'] as String;
          final duracao = duracaoStr == '12h' ? Duracao.dozeHoras : Duracao.vinteQuatroHoras;
          
          final plantao = Plantao(
            id: id,
            local: local,
            dataHora: DateTime.parse(data['data_hora'] as String),
            duracao: duracao,
            valor: (data['valor'] as num).toDouble(),
            previsaoPagamento: DateTime.parse(data['previsao_pagamento'] as String),
            criadoEm: DateTime.parse(data['criado_em'] as String),
            atualizadoEm: remoteUpdatedAt,
            ativo: data['ativo'] as bool? ?? true,
            userId: data['user_id'] as String,
          );
          
          plantoesBox.put(id, plantao);
        }
      }
      
      // Atualiza timestamp da última sincronização
      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('Erro ao processar mudanças remotas de Plantões: $e');
    }
  }

  /// Atualiza status de sincronização
  static void _updateStatus(SyncStatus status, [String? errorMessage]) {
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  /// Adiciona operação à fila de pendentes
  static void addPendingOperation(PendingOperation operation) {
    _pendingOperations.add(operation);
  }

  /// Limpa recursos
  static void dispose() {
    _statusController.close();
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

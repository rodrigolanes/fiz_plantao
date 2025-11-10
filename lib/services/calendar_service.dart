import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../config/config_helper.dart';
import '../models/plantao.dart';
import 'google_sign_in_service.dart';
import 'log_service.dart';

/// Serviço para integração com Google Calendar
///
/// Cria e gerencia um calendário dedicado "Fiz Plantão" com eventos de:
/// - Plantões (com data, hora, duração, local e valor)
/// - Pagamentos previstos
class CalendarService {
  static const String _calendarIdKey = 'google_calendar_id';
  static const String _syncEnabledKey = 'calendar_sync_enabled';
  static const String _calendarName = 'Fiz Plantão';
  static const String _timeZone = 'America/Sao_Paulo';

  // Cores do Google Calendar
  static const String _corPlantao = '9'; // Azul
  static const String _corPagamento = '10'; // Verde

  static final GoogleSignIn _googleSignIn = GoogleSignInService.instance;

  /// Verificar se integração com Google está habilitada
  static bool get isGoogleIntegrationEnabled {
    return ConfigHelper.isGoogleIntegrationEnabled;
  }

  /// Verifica se a sincronização com Google Calendar está habilitada
  static Future<bool> get isSyncEnabled async {
    if (!isGoogleIntegrationEnabled) return false;
    final box = await Hive.openBox('config');
    return box.get(_syncEnabledKey, defaultValue: false);
  }

  /// Habilita ou desabilita a sincronização com Google Calendar
  static Future<void> setSyncEnabled(bool enabled) async {
    final box = await Hive.openBox('config');
    await box.put(_syncEnabledKey, enabled);

    if (enabled) {
      // Garantir que o calendário dedicado existe
      await _ensureCalendarExists();
    }
  }

  /// Obtém o ID do calendário "Fiz Plantão" do cache
  static Future<String?> _getCachedCalendarId() async {
    final box = await Hive.openBox('config');
    return box.get(_calendarIdKey);
  }

  /// Salva o ID do calendário no cache
  static Future<void> _cacheCalendarId(String calendarId) async {
    final box = await Hive.openBox('config');
    await box.put(_calendarIdKey, calendarId);
  }

  /// Garante que o calendário dedicado "Fiz Plantão" existe
  /// Cria se necessário e retorna o ID
  static Future<String> _ensureCalendarExists() async {
    // Verificar cache primeiro
    final cachedId = await _getCachedCalendarId();
    if (cachedId != null) {
      // Validar que o calendário ainda existe
      try {
        final client = await _getAuthenticatedClient();
        if (client == null) throw 'Não autenticado';

        final calendarApi = CalendarApi(client);
        await calendarApi.calendars.get(cachedId);
        return cachedId; // Calendário existe
      } catch (e) {
        // Calendário foi deletado, criar novo
        LogService.calendar('Calendário em cache não encontrado, criando novo', e);
      }
    }

    // Criar novo calendário
    return await _createFizPlantaoCalendar();
  }

  /// Cria um novo calendário "Fiz Plantão"
  static Future<String> _createFizPlantaoCalendar() async {
    final client = await _getAuthenticatedClient();
    if (client == null) throw 'Não autenticado com Google';

    final calendarApi = CalendarApi(client);

    // Buscar se já existe um calendário com o nome "Fiz Plantão"
    try {
      final calendarios = await calendarApi.calendarList.list();
      if (calendarios.items != null) {
        for (final cal in calendarios.items!) {
          if (cal.summary == _calendarName) {
            LogService.calendar('Calendário "$_calendarName" já existe (ID: ${cal.id})');
            // Salvar ID no cache
            await _cacheCalendarId(cal.id!);
            return cal.id!;
          }
        }
      }
    } catch (e) {
      LogService.calendar('Erro ao buscar calendários existentes', e);
      // Continuar e tentar criar
    }

    // Criar novo calendário se não existe
    LogService.calendar('Criando novo calendário "$_calendarName"');
    final novoCalendario = Calendar(
      summary: _calendarName,
      description: 'Calendário de plantões e pagamentos do app Fiz Plantão',
      timeZone: _timeZone,
    );

    final calendarioCriado = await calendarApi.calendars.insert(novoCalendario);
    final calendarId = calendarioCriado.id!;

    // Salvar ID no cache
    await _cacheCalendarId(calendarId);

    LogService.calendar('Calendário criado com sucesso (ID: $calendarId)');
    return calendarId;
  }

  /// Obtém o client autenticado do Google
  static Future<dynamic> _getAuthenticatedClient() async {
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) return null;

    return await _googleSignIn.authenticatedClient();
  }

  /// Cria ou atualiza um evento de plantão no Google Calendar
  /// Retorna o ID do evento criado/atualizado
  static Future<String?> criarEventoPlantao(Plantao plantao) async {
    if (!await isSyncEnabled) return null;

    try {
      final client = await _getAuthenticatedClient();
      if (client == null) return null;

      final calendarApi = CalendarApi(client);
      final calendarId = await _ensureCalendarExists();

      final dataFim = plantao.duracao == Duracao.dozeHoras
          ? plantao.dataHora.add(const Duration(hours: 12))
          : plantao.dataHora.add(const Duration(hours: 24));

      final dateFormatSemHora = DateFormat('dd/MM/yyyy', 'pt_BR');
      final currencyFormat = NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
        decimalDigits: 2,
      );

      final evento = Event(
        summary: 'Plantão - ${plantao.local.apelido}',
        description: '''
📍 Local: ${plantao.local.nome}
⏱️ Duração: ${plantao.duracao == Duracao.dozeHoras ? '12 horas' : '24 horas'}
💰 Valor: ${currencyFormat.format(plantao.valor)}
📅 Pagamento previsto: ${dateFormatSemHora.format(plantao.previsaoPagamento)}
${plantao.pago ? '✅ Pago' : '⏳ Pendente'}

Criado via app Fiz Plantão
        '''
            .trim(),
        start: EventDateTime(
          dateTime: plantao.dataHora,
          timeZone: _timeZone,
        ),
        end: EventDateTime(
          dateTime: dataFim,
          timeZone: _timeZone,
        ),
        colorId: _corPlantao,
        reminders: EventReminders(
          useDefault: false,
          overrides: [
            EventReminder(method: 'popup', minutes: 60), // 1 hora antes
            EventReminder(method: 'popup', minutes: 1440), // 1 dia antes
          ],
        ),
        extendedProperties: EventExtendedProperties(
          private: {
            'app': 'fiz_plantao',
            'type': 'plantao',
            'plantao_id': plantao.id,
          },
        ),
      );

      // Se já tem calendarEventId, verificar se o evento ainda existe
      if (plantao.calendarEventId != null) {
        try {
          // Primeiro, verifica se o evento realmente existe
          LogService.calendar('Verificando se evento existe: ${plantao.calendarEventId}');
          final eventoExistente = await calendarApi.events.get(calendarId, plantao.calendarEventId!);

          // Se chegou aqui, o evento existe - verificar se não está deletado
          if (eventoExistente.status == 'cancelled') {
            LogService.calendar('Evento foi deletado (status: cancelled), criando novo: ${plantao.local.apelido}');
            // Continua para criar novo evento
          } else {
            // Evento existe e está ativo - pode atualizar
            LogService.calendar('Evento existe e está ativo, atualizando: ${plantao.calendarEventId}');
            final resultado = await calendarApi.events.patch(evento, calendarId, plantao.calendarEventId!);
            LogService.calendar(
                'Evento de plantão atualizado com sucesso: ${plantao.local.apelido} (ID: ${resultado.id})');
            return plantao.calendarEventId;
          }
        } catch (e) {
          // Se falhar ao buscar (evento não existe), logar e continuar para criar novo
          LogService.calendar(
              'Evento não encontrado (ID: ${plantao.calendarEventId}), criando novo: ${plantao.local.apelido}', e);
          // Continua para criar novo evento abaixo
        }
      }

      // Criar novo evento
      try {
        LogService.calendar('Criando novo evento de plantão: ${plantao.local.apelido}');
        final eventoCriado = await calendarApi.events.insert(evento, calendarId);
        LogService.calendar(
            'Evento de plantão criado com sucesso: ${plantao.local.apelido} (Novo ID: ${eventoCriado.id})');
        return eventoCriado.id;
      } catch (e) {
        LogService.calendar('Erro ao criar novo evento de plantão no Google Calendar', e);
        return null;
      }
    } catch (e) {
      // Falha silenciosa - não bloqueia o save do plantão
      LogService.calendar('Erro ao criar evento de plantão no Google Calendar', e);
      return null;
    }
  }

  /// Cria um evento de pagamento previsto no Google Calendar
  /// Agrupa todos os plantões com a mesma data de pagamento
  static Future<void> criarEventoPagamento({
    required DateTime dataPagamento,
    required double valor,
    required String localNome,
    required String plantaoId,
  }) async {
    if (!await isSyncEnabled) return;

    try {
      final client = await _getAuthenticatedClient();
      if (client == null) return;

      final calendarApi = CalendarApi(client);
      final calendarId = await _ensureCalendarExists();

      // Buscar todos os plantões com mesma data de pagamento
      final plantoesBox = Hive.box<Plantao>('plantoes');
      final userId = plantoesBox.values.first.userId;

      final plantoesMesmaData = plantoesBox.values
          .where((p) =>
              p.userId == userId &&
              p.ativo &&
              p.previsaoPagamento.year == dataPagamento.year &&
              p.previsaoPagamento.month == dataPagamento.month &&
              p.previsaoPagamento.day == dataPagamento.day)
          .toList();

      // Ordenar por data do plantão
      plantoesMesmaData.sort((a, b) => a.dataHora.compareTo(b.dataHora));

      // Se não há plantões ativos para esta data, remover evento de pagamento
      if (plantoesMesmaData.isEmpty) {
        LogService.calendar(
            'Nenhum plantão ativo para data de pagamento ${dataPagamento.toString().substring(0, 10)}. Removendo evento de pagamento.');

        // Buscar evento de pagamento existente para remover
        final dataStr = '${dataPagamento.year.toString().padLeft(4, '0')}-'
            '${dataPagamento.month.toString().padLeft(2, '0')}-'
            '${dataPagamento.day.toString().padLeft(2, '0')}';
        final dataFimEvento = dataPagamento.add(const Duration(days: 1));
        final dataFimStr = '${dataFimEvento.year.toString().padLeft(4, '0')}-'
            '${dataFimEvento.month.toString().padLeft(2, '0')}-'
            '${dataFimEvento.day.toString().padLeft(2, '0')}';

        final eventosExistentes = await calendarApi.events.list(
          calendarId,
          privateExtendedProperty: ['type=pagamento'],
          timeMin: DateTime.parse(dataStr).toUtc(),
          timeMax: DateTime.parse(dataFimStr).toUtc(),
        );

        if (eventosExistentes.items != null && eventosExistentes.items!.isNotEmpty) {
          for (final evento in eventosExistentes.items!) {
            if (evento.id != null) {
              try {
                await calendarApi.events.delete(calendarId, evento.id!);
                LogService.calendar('Evento de pagamento removido: ${evento.id}');
              } catch (e) {
                LogService.calendar('Erro ao remover evento de pagamento (ID: ${evento.id})', e);
              }
            }
          }
        }
        return; // Não criar novo evento
      }

      final currencyFormat = NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
        decimalDigits: 2,
      );

      final dateFormat = DateFormat('dd/MM', 'pt_BR');

      // Calcular total
      final total = plantoesMesmaData.fold<double>(0, (sum, p) => sum + p.valor);

      // Montar descrição com lista de plantões
      final buffer = StringBuffer();
      buffer.writeln('💰 TOTAL: ${currencyFormat.format(total)}');
      buffer.writeln();
      buffer.writeln(plantoesMesmaData.length == 1 ? '📋 PLANTÃO:' : '📋 PLANTÕES:');

      for (final p in plantoesMesmaData) {
        final status = p.pago ? '✅' : '⏳';
        buffer.writeln(
            '$status ${dateFormat.format(p.dataHora)} - ${p.local.apelido}: ${currencyFormat.format(p.valor)}');
      }

      buffer.writeln();
      buffer.writeln('Criado via app Fiz Plantão');

      // Evento de dia inteiro - formato YYYY-MM-DD
      final dataStr = '${dataPagamento.year.toString().padLeft(4, '0')}-'
          '${dataPagamento.month.toString().padLeft(2, '0')}-'
          '${dataPagamento.day.toString().padLeft(2, '0')}';

      // Para dia inteiro, end date é o dia seguinte
      final dataFimEvento = dataPagamento.add(const Duration(days: 1));
      final dataFimStr = '${dataFimEvento.year.toString().padLeft(4, '0')}-'
          '${dataFimEvento.month.toString().padLeft(2, '0')}-'
          '${dataFimEvento.day.toString().padLeft(2, '0')}';

      // Verificar se já existe evento de pagamento para esta data
      final eventosExistentes = await calendarApi.events.list(
        calendarId,
        privateExtendedProperty: ['type=pagamento'],
        timeMin: DateTime.parse(dataStr).toUtc(),
        timeMax: DateTime.parse(dataFimStr).toUtc(),
      );

      if (eventosExistentes.items != null && eventosExistentes.items!.isNotEmpty) {
        // Verificar se o evento ainda existe e não foi deletado
        final eventoExistente = eventosExistentes.items!.first;
        try {
          // Primeiro, verificar se o evento existe e está ativo
          final eventoAtual = await calendarApi.events.get(calendarId, eventoExistente.id!);

          if (eventoAtual.status == 'cancelled') {
            LogService.calendar('Evento de pagamento foi deletado (status: cancelled). Criando novo evento.');
            // Não fazer return - criar novo evento abaixo
          } else {
            LogService.calendar('Evento de pagamento existe e está ativo. Atualizando...');

            // Atualizar evento existente
            final eventoAtualizado = Event(
              summary:
                  '💰 Pagamento Previsto (${plantoesMesmaData.length} ${plantoesMesmaData.length == 1 ? "plantão" : "plantões"})',
              description: buffer.toString().trim(),
            );

            await calendarApi.events.patch(
              eventoAtualizado,
              calendarId,
              eventoExistente.id!,
            );
            LogService.calendar(
                'Evento de pagamento atualizado: ${plantoesMesmaData.length} ${plantoesMesmaData.length == 1 ? "plantão" : "plantões"}');
            return; // Sucesso, sair da função
          }
        } catch (e) {
          // Se o evento não existe mais, criar um novo
          LogService.calendar('Erro ao verificar evento de pagamento (ID: ${eventoExistente.id}), criando novo', e);
        }
      }

      // Criar novo evento (se não existia ou se a atualização falhou)
      final evento = Event(
        summary:
            '💰 Pagamento Previsto (${plantoesMesmaData.length} ${plantoesMesmaData.length == 1 ? "plantão" : "plantões"})',
        description: buffer.toString().trim(),
        start: EventDateTime(date: DateTime.parse(dataStr)),
        end: EventDateTime(date: DateTime.parse(dataFimStr)),
        colorId: _corPagamento,
        reminders: EventReminders(
          useDefault: false,
          overrides: [
            EventReminder(method: 'popup', minutes: 0), // No dia
          ],
        ),
        extendedProperties: EventExtendedProperties(
          private: {
            'app': 'fiz_plantao',
            'type': 'pagamento',
            'data_pagamento': dataStr,
          },
        ),
      );

      await calendarApi.events.insert(evento, calendarId);
      LogService.calendar(
          'Evento de pagamento criado: ${plantoesMesmaData.length} ${plantoesMesmaData.length == 1 ? "plantão" : "plantões"}');
    } catch (e) {
      LogService.calendar('Erro ao criar evento de pagamento no Google Calendar', e);
    }
  }

  /// Atualiza o status de pagamento de um evento existente
  static Future<void> atualizarStatusPagamento({
    required String plantaoId,
    required bool pago,
  }) async {
    if (!await isSyncEnabled) return;

    try {
      final client = await _getAuthenticatedClient();
      if (client == null) return;

      final calendarApi = CalendarApi(client);
      final calendarId = await _ensureCalendarExists();

      // Buscar evento pelo plantaoId nas propriedades estendidas
      final eventos = await calendarApi.events.list(
        calendarId,
        privateExtendedProperty: ['plantao_id=$plantaoId'],
      );

      if (eventos.items == null || eventos.items!.isEmpty) return;

      for (final evento in eventos.items!) {
        if (evento.id == null) continue;

        // Atualizar descrição com novo status
        final descricao = evento.description ?? '';
        final novaDescricao = descricao.replaceAll(
          RegExp(r'(✅ Pago|⏳ Pendente)'),
          pago ? '✅ Pago' : '⏳ Pendente',
        );

        final eventoAtualizado = Event(
          description: novaDescricao,
        );

        await calendarApi.events.patch(
          eventoAtualizado,
          calendarId,
          evento.id!,
        );
      }
      LogService.calendar('Status de pagamento atualizado para plantão $plantaoId');
    } catch (e) {
      LogService.calendar('Erro ao atualizar status de pagamento', e);
    }
  }

  /// Remove eventos relacionados a um plantão usando o ID do evento
  static Future<void> removerEventoPlantao(String? calendarEventId) async {
    if (!await isSyncEnabled) {
      LogService.calendar('Sync não habilitado, evento não será removido');
      return;
    }

    if (calendarEventId == null) {
      LogService.calendar('calendarEventId é null, não há evento para remover');
      return;
    }

    try {
      final client = await _getAuthenticatedClient();
      if (client == null) {
        LogService.calendar('Cliente não autenticado, não pode remover evento');
        return;
      }

      final calendarApi = CalendarApi(client);
      final calendarId = await _ensureCalendarExists();

      LogService.calendar('Removendo evento do Calendar: $calendarEventId');
      await calendarApi.events.delete(calendarId, calendarEventId);
      LogService.calendar('Evento de plantão removido com sucesso: $calendarEventId');
    } catch (e) {
      LogService.calendar('Erro ao remover evento do plantão (ID: $calendarEventId)', e);
    }
  }

  /// Remove eventos relacionados a um plantão (fallback para plantões antigos sem calendarEventId)
  static Future<void> removerEventosPlantao(String plantaoId) async {
    if (!await isSyncEnabled) return;

    try {
      final client = await _getAuthenticatedClient();
      if (client == null) return;

      final calendarApi = CalendarApi(client);
      final calendarId = await _ensureCalendarExists();

      // Buscar todos os eventos relacionados ao plantão
      final eventos = await calendarApi.events.list(
        calendarId,
        privateExtendedProperty: ['plantao_id=$plantaoId'],
      );

      if (eventos.items == null) return;

      // Deletar cada evento encontrado
      for (final evento in eventos.items!) {
        if (evento.id != null) {
          await calendarApi.events.delete(calendarId, evento.id!);
        }
      }
      LogService.calendar('Eventos do plantão $plantaoId removidos');
    } catch (e) {
      LogService.calendar('Erro ao remover eventos do Google Calendar', e);
    }
  }

  /// Solicita permissão de acesso ao Google Calendar
  /// Retorna true se o usuário autorizou
  static Future<bool> requestCalendarPermission() async {
    try {
      final account = await _googleSignIn.signIn();
      LogService.calendar('Permissão do Google Calendar concedida');
      return account != null;
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_failed' && e.message?.contains('12500') == true) {
        LogService.warning('Erro de configuração OAuth - código 12500');
      } else {
        LogService.calendar('Erro ao solicitar permissão do Google Calendar', e);
      }
      return false;
    } catch (e) {
      LogService.calendar('Erro ao solicitar permissão do Google Calendar', e);
      return false;
    }
  }

  /// Desconecta do Google Calendar
  static Future<void> disconnect() async {
    await setSyncEnabled(false);
    // Não fazer signOut do GoogleSignIn para não afetar a autenticação do app
  }
}

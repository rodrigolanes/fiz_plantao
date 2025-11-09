import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../models/plantao.dart';
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

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [CalendarApi.calendarScope],
  );

  /// Verifica se a sincronização com Google Calendar está habilitada
  static Future<bool> get isSyncEnabled async {
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

    final novoCalendario = Calendar(
      summary: _calendarName,
      description: 'Calendário de plantões e pagamentos do app Fiz Plantão',
      timeZone: _timeZone,
    );

    final calendarioCriado = await calendarApi.calendars.insert(novoCalendario);
    final calendarId = calendarioCriado.id!;

    // Salvar ID no cache
    await _cacheCalendarId(calendarId);

    return calendarId;
  }

  /// Obtém o client autenticado do Google
  static Future<dynamic> _getAuthenticatedClient() async {
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) return null;

    return await _googleSignIn.authenticatedClient();
  }

  /// Cria um evento de plantão no Google Calendar
  static Future<void> criarEventoPlantao(Plantao plantao) async {
    if (!await isSyncEnabled) return;

    try {
      final client = await _getAuthenticatedClient();
      if (client == null) return;

      final calendarApi = CalendarApi(client);
      final calendarId = await _ensureCalendarExists();

      final dataFim = plantao.duracao == Duracao.dozeHoras
          ? plantao.dataHora.add(const Duration(hours: 12))
          : plantao.dataHora.add(const Duration(hours: 24));

      final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
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
📅 Pagamento previsto: ${dateFormat.format(plantao.previsaoPagamento)}
${plantao.pago ? '✅ Pago' : '⏳ Pendente'}

Criado via app Fiz Plantão
        '''
            .trim(),
        start: EventDateTime(dateTime: plantao.dataHora),
        end: EventDateTime(dateTime: dataFim),
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

      await calendarApi.events.insert(evento, calendarId);
      LogService.calendar('Evento de plantão criado: ${plantao.local.apelido}');
    } catch (e) {
      // Falha silenciosa - não bloqueia o save do plantão
      LogService.calendar('Erro ao criar evento de plantão no Google Calendar', e);
    }
  }

  /// Cria um evento de pagamento previsto no Google Calendar
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

      final currencyFormat = NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
        decimalDigits: 2,
      );

      // Evento de dia inteiro
      final dataInicio = DateTime(
        dataPagamento.year,
        dataPagamento.month,
        dataPagamento.day,
      );

      final evento = Event(
        summary: '💰 Pagamento Previsto - $localNome',
        description: '''
💵 Valor: ${currencyFormat.format(valor)}
📍 Local: $localNome
⏳ Status: Pendente

Criado via app Fiz Plantão
        '''
            .trim(),
        start: EventDateTime(date: dataInicio),
        end: EventDateTime(date: dataInicio),
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
            'plantao_id': plantaoId,
          },
        ),
      );

      await calendarApi.events.insert(evento, calendarId);
      LogService.calendar('Evento de pagamento criado: $localNome');
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

  /// Remove eventos relacionados a um plantão
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

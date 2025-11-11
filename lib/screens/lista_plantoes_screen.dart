import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/config_helper.dart';
import '../models/plantao.dart';
import '../services/auth_service.dart';
import '../services/calendar_service.dart';
import '../services/database_service.dart';
import 'cadastro_plantao_screen.dart';
import 'lista_locais_screen.dart';
import 'login_screen.dart';
import 'relatorios_screen.dart';

class ListaPlantoesScreen extends StatefulWidget {
  const ListaPlantoesScreen({super.key});

  @override
  State<ListaPlantoesScreen> createState() => _ListaPlantoesScreenState();
}

class _ListaPlantoesScreenState extends State<ListaPlantoesScreen> {
  String? _localFiltroId;
  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _filtrarDataAtual = true; // Filtro padrão: hoje ou posterior

  @override
  void initState() {
    super.initState();
    _dataInicio = DateTime.now(); // Padrão: a partir de hoje
  }

  void _carregarDados() {
    setState(() {});
  }

  List<Plantao> _aplicarFiltros(List<Plantao> plantoes) {
    var filtrados = plantoes;

    // Filtro por local
    if (_localFiltroId != null) {
      filtrados = filtrados.where((p) => p.local.id == _localFiltroId).toList();
    }

    // Filtro por data
    if (_filtrarDataAtual && _dataInicio != null) {
      final hoje = DateTime(_dataInicio!.year, _dataInicio!.month, _dataInicio!.day);
      filtrados = filtrados.where((p) {
        final dataPlantao = DateTime(p.dataHora.year, p.dataHora.month, p.dataHora.day);
        return dataPlantao.isAtSameMomentAs(hoje) || dataPlantao.isAfter(hoje);
      }).toList();
    } else if (_dataInicio != null || _dataFim != null) {
      filtrados = filtrados.where((p) {
        final dataPlantao = DateTime(p.dataHora.year, p.dataHora.month, p.dataHora.day);
        if (_dataInicio != null && _dataFim != null) {
          final inicio = DateTime(_dataInicio!.year, _dataInicio!.month, _dataInicio!.day);
          final fim = DateTime(_dataFim!.year, _dataFim!.month, _dataFim!.day);
          return (dataPlantao.isAtSameMomentAs(inicio) || dataPlantao.isAfter(inicio)) &&
              (dataPlantao.isAtSameMomentAs(fim) || dataPlantao.isBefore(fim));
        } else if (_dataInicio != null) {
          final inicio = DateTime(_dataInicio!.year, _dataInicio!.month, _dataInicio!.day);
          return dataPlantao.isAtSameMomentAs(inicio) || dataPlantao.isAfter(inicio);
        } else if (_dataFim != null) {
          final fim = DateTime(_dataFim!.year, _dataFim!.month, _dataFim!.day);
          return dataPlantao.isAtSameMomentAs(fim) || dataPlantao.isBefore(fim);
        }
        return true;
      }).toList();
    }

    return filtrados;
  }

  void _limparFiltros() {
    setState(() {
      _localFiltroId = null;
      _dataInicio = DateTime.now();
      _dataFim = null;
      _filtrarDataAtual = true;
    });
  }

  Future<void> _selecionarPeriodo() async {
    final resultado = await showDialog<Map<String, DateTime?>>(
      context: context,
      builder: (_) => _DialogSelecionarPeriodo(
        dataInicio: _dataInicio,
        dataFim: _dataFim,
      ),
    );

    if (resultado != null && mounted) {
      setState(() {
        _dataInicio = resultado['inicio'];
        _dataFim = resultado['fim'];
        _filtrarDataAtual = false;
      });
    }
  }

  Future<void> _gerenciarLocais() async {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => const ListaLocaisScreen(),
      ),
    );
    if (!mounted) return;
    _carregarDados();
  }

  String _formatarDataHora(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  String _formatarData(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatarValor(double valor) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor);
  }

  Future<void> _navegarParaCadastro([Plantao? plantao]) async {
    final ativos = DatabaseService.getLocaisAtivos();
    if (ativos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre um local ativo antes de criar um plantão.')),
      );
      return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final resultado = await navigator.push<Plantao>(
      MaterialPageRoute(
        builder: (_) => CadastroPlantaoScreen(
          plantao: plantao,
          locais: ativos,
        ),
      ),
    );
    if (!mounted) return;
    if (resultado != null) {
      await DatabaseService.savePlantao(resultado);
      if (!mounted) return;
      _carregarDados();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            plantao == null ? 'Plantão cadastrado com sucesso!' : 'Plantão atualizado com sucesso!',
          ),
        ),
      );
    }
  }

  void _confirmarExclusao(Plantao plantao) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja realmente excluir o plantão em ${plantao.local.apelido}?',
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseService.deletePlantao(plantao.id);
              navigator.pop();
              if (!mounted) return;
              _carregarDados();
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('Plantão excluído com sucesso!')),
              );
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(DateTime previsaoPagamento) {
    final hoje = DateTime.now();
    final diferenca = previsaoPagamento.difference(hoje).inDays;

    if (diferenca < 0) {
      return Colors.red; // Atrasado
    } else if (diferenca <= 7) {
      return Colors.orange; // Próximo
    } else {
      return Colors.green; // No prazo
    }
  }

  Future<void> _configurarGoogleCalendar() async {
    final syncAtual = await CalendarService.isSyncEnabled;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.calendar_month, color: Colors.teal),
            SizedBox(width: 8),
            Text('Google Calendar'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              syncAtual ? 'Sincronização ativa' : 'Sincronização desativada',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Quando ativada, seus plantões e previsões de pagamento serão adicionados automaticamente ao Google Calendar.',
            ),
            const SizedBox(height: 12),
            const Text(
              '✓ Calendário dedicado "Fiz Plantão"\n'
              '✓ Eventos com data, hora e valor\n'
              '✓ Lembretes automáticos\n'
              '✓ Sincronização em todos os dispositivos',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          if (syncAtual)
            FilledButton(
              onPressed: () => Navigator.pop(context, false),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Desativar'),
            )
          else
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ativar'),
            ),
        ],
      ),
    );

    if (resultado == null) return;

    if (!mounted) return;

    if (resultado) {
      // Ativar sincronização
      final permissao = await CalendarService.requestCalendarPermission();
      if (!permissao) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível conectar ao Google Calendar. '
              'Verifique se você está conectado com uma conta Google.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      await CalendarService.setSyncEnabled(true);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Google Calendar ativado! Novos plantões serão sincronizados.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Desativar sincronização
      await CalendarService.disconnect();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Google Calendar desativado'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locaisAtivos = DatabaseService.getLocaisAtivos();
    final plantoesAtivos = DatabaseService.getPlantoesAtivos();
    final plantoesFiltrados = _aplicarFiltros(plantoesAtivos);
    final temFiltrosAtivos = _localFiltroId != null || !_filtrarDataAtual || _dataFim != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Plantões'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RelatoriosScreen(),
                ),
              );
            },
            tooltip: 'Relatórios',
          ),
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _gerenciarLocais,
            tooltip: 'Gerenciar Locais',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'calendar') {
                _configurarGoogleCalendar();
              } else if (value == 'logout') {
                final navigator = Navigator.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Sair'),
                    content: const Text('Deseja realmente sair?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sair'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await AuthService.logout();
                  if (!mounted) return;

                  navigator.pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              // Google Calendar (só exibe se habilitado)
              if (ConfigHelper.isGoogleIntegrationEnabled)
                const PopupMenuItem(
                  value: 'calendar',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month),
                      SizedBox(width: 8),
                      Text('Google Calendar'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sair'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Área de filtros
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.teal[50],
            child: Column(
              children: [
                Row(
                  children: [
                    // Filtro por local
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _localFiltroId,
                        decoration: InputDecoration(
                          labelText: 'Local',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.location_on, size: 20),
                        ),
                        hint: const Text('Todos os locais'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Todos os locais'),
                          ),
                          ...locaisAtivos.map((local) {
                            return DropdownMenuItem<String>(
                              value: local.id,
                              child: Text(local.apelido),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _localFiltroId = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botão de filtro (ícone)
                    IconButton(
                      onPressed: _selecionarPeriodo,
                      icon: const Icon(Icons.filter_list),
                      tooltip: 'Filtrar por período',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                  ],
                ),
                // Indicador de filtro ativo
                if (!_filtrarDataAtual || _dataFim != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.teal[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_list, size: 16, color: Colors.teal[800]),
                          const SizedBox(width: 6),
                          Text(
                            _dataFim != null
                                ? '${DateFormat('dd/MM').format(_dataInicio!)} - ${DateFormat('dd/MM').format(_dataFim!)}'
                                : 'Desde ${DateFormat('dd/MM').format(_dataInicio!)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.teal[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (temFiltrosAtivos)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${plantoesFiltrados.length} de ${plantoesAtivos.length} plantões',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.teal[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _limparFiltros,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Limpar'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Lista de plantões
          Expanded(
            child: (plantoesFiltrados.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          temFiltrosAtivos
                              ? Icons.filter_alt_off
                              : (locaisAtivos.isEmpty ? Icons.location_off : Icons.medical_services_outlined),
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          temFiltrosAtivos
                              ? 'Nenhum plantão encontrado'
                              : (locaisAtivos.isEmpty ? 'Nenhum local cadastrado' : 'Nenhum plantão cadastrado'),
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          temFiltrosAtivos
                              ? 'Tente ajustar os filtros acima'
                              : (locaisAtivos.isEmpty
                                  ? 'Crie seu primeiro local para cadastrar plantões.'
                                  : 'Clique no botão + para adicionar'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (locaisAtivos.isEmpty && !temFiltrosAtivos)
                          ElevatedButton.icon(
                            onPressed: _gerenciarLocais,
                            icon: const Icon(Icons.add_location_alt),
                            label: const Text('Cadastrar Local'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: plantoesFiltrados.length,
                    itemBuilder: (context, index) {
                      final plantao = plantoesFiltrados[index];
                      final statusColor = _getStatusColor(plantao.previsaoPagamento);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: InkWell(
                          onTap: () => _navegarParaCadastro(plantao),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            plantao.local.apelido,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            plantao.local.nome,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _navegarParaCadastro(plantao),
                                      tooltip: 'Editar',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _confirmarExclusao(plantao),
                                      tooltip: 'Excluir',
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatarDataHora(plantao.dataHora),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.access_time, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      plantao.duracao.label,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            _formatarValor(plantao.valor),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: plantao.pago
                                                  ? Colors.green.withValues(alpha: 0.15)
                                                  : Colors.orange.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  plantao.pago ? Icons.check_circle : Icons.attach_money,
                                                  size: 14,
                                                  color: plantao.pago ? Colors.green : Colors.orange,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  plantao.pago ? 'Pago' : 'Pendente',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: plantao.pago ? Colors.green : Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: statusColor),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_month,
                                            size: 14,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatarData(plantao.previsaoPagamento),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: locaisAtivos.isEmpty ? null : () => _navegarParaCadastro(),
        backgroundColor: locaisAtivos.isEmpty ? Colors.grey[300] : null,
        foregroundColor: locaisAtivos.isEmpty ? Colors.grey[500] : null,
        icon: const Icon(Icons.add),
        label: const Text('Novo Plantão'),
      ),
    );
  }
}

// Dialog para seleção de período personalizado
class _DialogSelecionarPeriodo extends StatefulWidget {
  final DateTime? dataInicio;
  final DateTime? dataFim;

  const _DialogSelecionarPeriodo({
    this.dataInicio,
    this.dataFim,
  });

  @override
  State<_DialogSelecionarPeriodo> createState() => _DialogSelecionarPeriodoState();
}

class _DialogSelecionarPeriodoState extends State<_DialogSelecionarPeriodo> {
  late DateTime? _inicio;
  late DateTime? _fim;
  final _inicioController = TextEditingController();
  final _fimController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inicio = widget.dataInicio;
    _fim = widget.dataFim;
    if (_inicio != null) {
      _inicioController.text = DateFormat('dd/MM/yyyy').format(_inicio!);
    }
    if (_fim != null) {
      _fimController.text = DateFormat('dd/MM/yyyy').format(_fim!);
    }
  }

  @override
  void dispose() {
    _inicioController.dispose();
    _fimController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(bool isInicio) async {
    final data = await showDatePicker(
      context: context,
      initialDate: (isInicio ? _inicio : _fim) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );

    if (data != null && mounted) {
      setState(() {
        if (isInicio) {
          _inicio = data;
          _inicioController.text = DateFormat('dd/MM/yyyy').format(data);
        } else {
          _fim = data;
          _fimController.text = DateFormat('dd/MM/yyyy').format(data);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecionar Período'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _inicioController,
            decoration: const InputDecoration(
              labelText: 'Data Início',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () => _selecionarData(true),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fimController,
            decoration: const InputDecoration(
              labelText: 'Data Fim (opcional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
              helperText: 'Deixe vazio para sem limite',
            ),
            readOnly: true,
            onTap: () => _selecionarData(false),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _inicio = DateTime.now();
                      _fim = null;
                      _inicioController.text = DateFormat('dd/MM/yyyy').format(_inicio!);
                      _fimController.clear();
                    });
                  },
                  child: const Text('Próximos'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final agora = DateTime.now();
                    setState(() {
                      _inicio = DateTime(agora.year, agora.month, 1);
                      _fim = DateTime(agora.year, agora.month + 1, 0);
                      _inicioController.text = DateFormat('dd/MM/yyyy').format(_inicio!);
                      _fimController.text = DateFormat('dd/MM/yyyy').format(_fim!);
                    });
                  },
                  child: const Text('Este mês'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop({
              'inicio': _inicio,
              'fim': _fim,
            });
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/local.dart';
import '../models/plantao.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/primary_action_buttons.dart';
import 'lista_locais_screen.dart';

class CadastroPlantaoScreen extends StatefulWidget {
  final Plantao? plantao;
  final List<Local> locais;

  const CadastroPlantaoScreen({
    super.key,
    this.plantao,
    this.locais = const [],
  });

  @override
  State<CadastroPlantaoScreen> createState() => _CadastroPlantaoScreenState();
}

class _CadastroPlantaoScreenState extends State<CadastroPlantaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _dataHoraController = TextEditingController();
  final _previsaoPagamentoController = TextEditingController();

  DateTime? _dataHoraSelecionada;
  DateTime? _previsaoPagamentoSelecionada;
  Duracao _duracaoSelecionada = Duracao.dozeHoras;
  String? _localIdSelecionado;
  late List<Local> _locaisDisponiveis;
  bool _pago = false;

  @override
  void initState() {
    super.initState();
    // Remove duplicatas por ID (manter apenas o primeiro de cada ID)
    final idsVistos = <String>{};
    _locaisDisponiveis = widget.locais.where((local) {
      if (idsVistos.contains(local.id)) {
        return false; // Duplicata, pular
      }
      idsVistos.add(local.id);
      return true;
    }).toList();

    if (widget.plantao != null) {
      _localIdSelecionado = widget.plantao!.local.id;
      _valorController.text = widget.plantao!.valor.toStringAsFixed(2).replaceAll('.', ',');
      _dataHoraSelecionada = widget.plantao!.dataHora;
      _dataHoraController.text = _formatarDataHora(_dataHoraSelecionada!);
      _previsaoPagamentoSelecionada = widget.plantao!.previsaoPagamento;
      _previsaoPagamentoController.text = _formatarData(_previsaoPagamentoSelecionada!);
      _duracaoSelecionada = widget.plantao!.duracao;
      _pago = widget.plantao!.pago;
    }
  }

  @override
  void dispose() {
    _valorController.dispose();
    _dataHoraController.dispose();
    _previsaoPagamentoController.dispose();
    super.dispose();
  }

  Future<void> _navegarParaGerenciarLocais() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ListaLocaisScreen(),
      ),
    );
    if (mounted) {
      setState(() {
        // Recarrega locais do Hive e remove duplicatas
        final locaisHive = DatabaseService.instance.getLocaisAtivos();
        final idsVistos = <String>{};
        _locaisDisponiveis = locaisHive.where((local) {
          if (idsVistos.contains(local.id)) {
            return false;
          }
          idsVistos.add(local.id);
          return true;
        }).toList();

        // Se o local selecionado foi removido/inativado, limpar seleção
        if (_localIdSelecionado != null && !_locaisDisponiveis.any((l) => l.id == _localIdSelecionado)) {
          _localIdSelecionado = null;
        }
      });
    }
  }

  String _formatarDataHora(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  String _formatarData(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _selecionarDataHora() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataHoraSelecionada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );

    if (data != null && mounted) {
      final hora = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dataHoraSelecionada ?? DateTime.now()),
      );

      if (hora != null && mounted) {
        setState(() {
          _dataHoraSelecionada = DateTime(
            data.year,
            data.month,
            data.day,
            hora.hour,
            hora.minute,
          );
          _dataHoraController.text = _formatarDataHora(_dataHoraSelecionada!);
        });
      }
    }
  }

  Future<void> _selecionarPrevisaoPagamento() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _previsaoPagamentoSelecionada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );

    if (data != null && mounted) {
      setState(() {
        _previsaoPagamentoSelecionada = data;
        _previsaoPagamentoController.text = _formatarData(data);
      });
    }
  }

  void _confirmarExclusao() {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja realmente excluir o plantão em ${widget.plantao!.local.apelido}?',
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              await DatabaseService.instance.deletePlantao(widget.plantao!.id);
              if (!mounted) return;
              navigator.pop(); // Fecha o dialog
              navigator.pop(null); // Volta para lista
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Plantão excluído com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      if (_localIdSelecionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecione um local')),
        );
        return;
      }

      if (_dataHoraSelecionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione a data e hora do plantão')),
        );
        return;
      }

      if (_previsaoPagamentoSelecionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione a previsão de pagamento')),
        );
        return;
      }

      // Buscar o objeto Local pelo ID
      final localSelecionado = _locaisDisponiveis.firstWhere(
        (l) => l.id == _localIdSelecionado,
      );

      final agora = DateTime.now();
      // Converte texto com vírgula para double (pt-BR)
      final valorTexto = _valorController.text.trim().replaceAll('.', '').replaceAll(',', '.');
      final valorDouble = double.parse(valorTexto);
      final userId = AuthService.instance.currentUserId;

      if (userId == null) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Erro: usuário não autenticado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final plantao = Plantao(
        id: widget.plantao?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        local: localSelecionado,
        dataHora: _dataHoraSelecionada!,
        duracao: _duracaoSelecionada,
        valor: valorDouble,
        previsaoPagamento: _previsaoPagamentoSelecionada!,
        pago: _pago,
        criadoEm: widget.plantao?.criadoEm ?? agora,
        atualizadoEm: agora,
        userId: widget.plantao?.userId ?? userId,
        calendarEventId: widget.plantao?.calendarEventId,
        calendarPaymentEventId: widget.plantao?.calendarPaymentEventId,
      );

      Navigator.of(context).pop(plantao);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.plantao != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? 'Editar Plantão' : 'Novo Plantão'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: isEdicao
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmarExclusao(),
                  tooltip: 'Excluir plantão',
                ),
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _localIdSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Local',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    hint: const Text('Selecione o local'),
                    items: _locaisDisponiveis.map((local) {
                      return DropdownMenuItem(
                        value: local.id,
                        child: Text(local.apelido),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _localIdSelecionado = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor, selecione um local';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: _navegarParaGerenciarLocais,
                  tooltip: 'Gerenciar locais',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dataHoraController,
              decoration: const InputDecoration(
                labelText: 'Data e Hora',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: _selecionarDataHora,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, selecione a data e hora';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Duracao>(
              initialValue: _duracaoSelecionada,
              decoration: const InputDecoration(
                labelText: 'Duração',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time),
              ),
              items: Duracao.values.map((duracao) {
                return DropdownMenuItem(
                  value: duracao,
                  child: Text(duracao.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _duracaoSelecionada = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valorController,
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                helperText: 'Use vírgula para decimais. Ex: 1.234,56',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                _MoedaPtBrFormatter(),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe o valor';
                }
                // Normaliza para double
                final texto = value.trim();
                final normalizado = texto.replaceAll('.', '').replaceAll(',', '.');
                final valorNum = double.tryParse(normalizado);
                if (valorNum == null || valorNum <= 0) {
                  return 'Informe um valor válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _previsaoPagamentoController,
              decoration: const InputDecoration(
                labelText: 'Previsão de Pagamento',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_month),
              ),
              readOnly: true,
              onTap: _selecionarPrevisaoPagamento,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, selecione a previsão de pagamento';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: const Text('Plantão Pago'),
                subtitle: Text(_pago ? 'Pagamento recebido' : 'Pagamento pendente'),
                value: _pago,
                onChanged: (value) {
                  setState(() {
                    _pago = value;
                  });
                },
                secondary: Icon(
                  _pago ? Icons.check_circle : Icons.pending,
                  color: _pago ? Colors.green : Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryActionButtons(
              onCancel: () => Navigator.of(context).pop(),
              onSave: _salvar,
              saveEnabled: true,
            ),
          ],
        ),
      ),
    );
  }
}

// Formata entrada de moeda estilo pt-BR enquanto digita.
class _MoedaPtBrFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    // Remove tudo exceto dígitos
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    // Limita tamanho para evitar overflow absurdo (ex: > 15 dígitos)
    final limited = digits.length > 15 ? digits.substring(0, 15) : digits;
    // Constrói com separadores: últimos 2 dígitos são decimais
    String centavos;
    String inteiros;
    if (limited.length <= 2) {
      inteiros = '0';
      centavos = limited.padLeft(2, '0');
    } else {
      inteiros = limited.substring(0, limited.length - 2);
      centavos = limited.substring(limited.length - 2);
    }
    // Remove zeros à esquerda da parte inteira (mantém '0' se resultado vazio)
    inteiros = inteiros.replaceFirst(RegExp(r'^0+'), '');
    if (inteiros.isEmpty) {
      inteiros = '0';
    }
    // Adiciona pontos a cada 3 dígitos da parte inteira
    final inteirosComPontos = _addThousandsSeparator(inteiros);
    final resultado = '$inteirosComPontos,$centavos';
    return TextEditingValue(
      text: resultado,
      selection: TextSelection.collapsed(offset: resultado.length),
    );
  }

  String _addThousandsSeparator(String value) {
    final buf = StringBuffer();
    final chars = value.split('').reversed.toList();
    for (int i = 0; i < chars.length; i++) {
      if (i != 0 && i % 3 == 0) buf.write('.');
      buf.write(chars[i]);
    }
    return buf.toString().split('').reversed.join();
  }
}

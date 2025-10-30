import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/plantao.dart';
import '../models/local.dart';
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
  Local? _localSelecionado;
  late List<Local> _locaisDisponiveis;

  @override
  void initState() {
    super.initState();
    _locaisDisponiveis = List.from(widget.locais);
    
    if (widget.plantao != null) {
      _localSelecionado = widget.plantao!.local;
      _valorController.text = widget.plantao!.valor.toStringAsFixed(2);
      _dataHoraSelecionada = widget.plantao!.dataHora;
      _dataHoraController.text = _formatarDataHora(_dataHoraSelecionada!);
      _previsaoPagamentoSelecionada = widget.plantao!.previsaoPagamento;
      _previsaoPagamentoController.text =
          _formatarData(_previsaoPagamentoSelecionada!);
      _duracaoSelecionada = widget.plantao!.duracao;
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
    // Aqui você precisará recarregar os locais do banco de dados
    // Por enquanto, apenas atualizamos a tela
    if (mounted) {
      setState(() {});
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

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      if (_localSelecionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione um local')),
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

      final agora = DateTime.now();
      final plantao = Plantao(
        id: widget.plantao?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        local: _localSelecionado!,
        dataHora: _dataHoraSelecionada!,
        duracao: _duracaoSelecionada,
        valor: double.parse(_valorController.text.replaceAll(',', '.')),
        previsaoPagamento: _previsaoPagamentoSelecionada!,
        criadoEm: widget.plantao?.criadoEm ?? agora,
        atualizadoEm: agora,
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
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Local>(
                    value: _localSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Local',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    hint: const Text('Selecione o local'),
                    items: _locaisDisponiveis.map((local) {
                      return DropdownMenuItem(
                        value: local,
                        child: Text('${local.apelido} - ${local.nome}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _localSelecionado = value;
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
              value: _duracaoSelecionada,
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
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe o valor';
                }
                final valorNum = double.tryParse(value.replaceAll(',', '.'));
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
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Cancelar'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _salvar,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Salvar'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

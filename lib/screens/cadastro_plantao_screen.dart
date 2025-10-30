import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/primary_action_buttons.dart';
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
    final listaAtualizada = await Navigator.of(context).push<List<Local>>(
      MaterialPageRoute(
        builder: (context) => ListaLocaisScreen(locaisIniciais: _locaisDisponiveis),
      ),
    );
    if (listaAtualizada != null && mounted) {
      setState(() {
        _locaisDisponiveis = listaAtualizada;
        // Se o local selecionado foi removido, limpar seleção
        if (_localSelecionado != null &&
            !_locaisDisponiveis.any((l) => l.id == _localSelecionado!.id)) {
          _localSelecionado = null;
        } else if (_localSelecionado != null) {
          // Atualiza referência caso tenha sido editado
          _localSelecionado = _locaisDisponiveis.firstWhere(
            (l) => l.id == _localSelecionado!.id,
            orElse: () => _localSelecionado!,
          );
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
      // Converte texto com vírgula para double (pt-BR)
      final valorTexto = _valorController.text.trim().replaceAll('.', '').replaceAll(',', '.');
      final valorDouble = double.parse(valorTexto);

      final plantao = Plantao(
        id: widget.plantao?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        local: _localSelecionado!,
        dataHora: _dataHoraSelecionada!,
        duracao: _duracaoSelecionada,
        valor: valorDouble,
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
                    initialValue: _localSelecionado,
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
